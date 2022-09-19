
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	42c78793          	addi	a5,a5,1068 # 80006490 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	b30080e7          	jalr	-1232(ra) # 80001c5c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	742080e7          	jalr	1858(ra) # 80001906 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	df4080e7          	jalr	-524(ra) # 80001fc8 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	9f6080e7          	jalr	-1546(ra) # 80001c06 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	9c0080e7          	jalr	-1600(ra) # 80001cb2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	bfc080e7          	jalr	-1028(ra) # 80002042 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	a1078793          	addi	a5,a5,-1520 # 80022e88 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00001097          	auipc	ra,0x1
    800008a4:	7a2080e7          	jalr	1954(ra) # 80002042 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	69c080e7          	jalr	1692(ra) # 80001fc8 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	d66080e7          	jalr	-666(ra) # 800018e4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	d34080e7          	jalr	-716(ra) # 800018e4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	d28080e7          	jalr	-728(ra) # 800018e4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	d10080e7          	jalr	-752(ra) # 800018e4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	cd0080e7          	jalr	-816(ra) # 800018e4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ca4080e7          	jalr	-860(ra) # 800018e4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:


// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	a3e080e7          	jalr	-1474(ra) # 800018d4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17e70713          	addi	a4,a4,382 # 8000901c <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	a22080e7          	jalr	-1502(ra) # 800018d4 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	022080e7          	jalr	34(ra) # 80002ef6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	5f4080e7          	jalr	1524(ra) # 800064d0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	54a080e7          	jalr	1354(ra) # 8000242e <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	ee2080e7          	jalr	-286(ra) # 80001e26 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	f82080e7          	jalr	-126(ra) # 80002ece <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	fa2080e7          	jalr	-94(ra) # 80002ef6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	55e080e7          	jalr	1374(ra) # 800064ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	56c080e7          	jalr	1388(ra) # 800064d0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	748080e7          	jalr	1864(ra) # 800036b4 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	dd8080e7          	jalr	-552(ra) # 80003d4c <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	d82080e7          	jalr	-638(ra) # 80004cfe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	66e080e7          	jalr	1646(ra) # 800065f2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	954080e7          	jalr	-1708(ra) # 800028e0 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	08f72123          	sw	a5,130(a4) # 8000901c <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	f2c48493          	addi	s1,s1,-212 # 80011780 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	312a0a13          	addi	s4,s4,786 # 80017b80 <cpus>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	19048493          	addi	s1,s1,400
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018d4:	1141                	addi	sp,sp,-16
    800018d6:	e422                	sd	s0,8(sp)
    800018d8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018da:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018dc:	2501                	sext.w	a0,a0
    800018de:	6422                	ld	s0,8(sp)
    800018e0:	0141                	addi	sp,sp,16
    800018e2:	8082                	ret

00000000800018e4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800018e4:	1141                	addi	sp,sp,-16
    800018e6:	e422                	sd	s0,8(sp)
    800018e8:	0800                	addi	s0,sp,16
    800018ea:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ec:	2781                	sext.w	a5,a5
    800018ee:	21800513          	li	a0,536
    800018f2:	02a787b3          	mul	a5,a5,a0
  return c;
}
    800018f6:	00016517          	auipc	a0,0x16
    800018fa:	28a50513          	addi	a0,a0,650 # 80017b80 <cpus>
    800018fe:	953e                	add	a0,a0,a5
    80001900:	6422                	ld	s0,8(sp)
    80001902:	0141                	addi	sp,sp,16
    80001904:	8082                	ret

0000000080001906 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001906:	1101                	addi	sp,sp,-32
    80001908:	ec06                	sd	ra,24(sp)
    8000190a:	e822                	sd	s0,16(sp)
    8000190c:	e426                	sd	s1,8(sp)
    8000190e:	1000                	addi	s0,sp,32
  push_off();
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	288080e7          	jalr	648(ra) # 80000b98 <push_off>
    80001918:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000191a:	2781                	sext.w	a5,a5
    8000191c:	21800713          	li	a4,536
    80001920:	02e787b3          	mul	a5,a5,a4
    80001924:	00016717          	auipc	a4,0x16
    80001928:	25c70713          	addi	a4,a4,604 # 80017b80 <cpus>
    8000192c:	97ba                	add	a5,a5,a4
    8000192e:	6384                	ld	s1,0(a5)
  pop_off();
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	308080e7          	jalr	776(ra) # 80000c38 <pop_off>
  return p;
}
    80001938:	8526                	mv	a0,s1
    8000193a:	60e2                	ld	ra,24(sp)
    8000193c:	6442                	ld	s0,16(sp)
    8000193e:	64a2                	ld	s1,8(sp)
    80001940:	6105                	addi	sp,sp,32
    80001942:	8082                	ret

0000000080001944 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001944:	1141                	addi	sp,sp,-16
    80001946:	e406                	sd	ra,8(sp)
    80001948:	e022                	sd	s0,0(sp)
    8000194a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000194c:	00000097          	auipc	ra,0x0
    80001950:	fba080e7          	jalr	-70(ra) # 80001906 <myproc>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	344080e7          	jalr	836(ra) # 80000c98 <release>

  if (first) {
    8000195c:	00007797          	auipc	a5,0x7
    80001960:	ef47a783          	lw	a5,-268(a5) # 80008850 <first.1708>
    80001964:	eb89                	bnez	a5,80001976 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001966:	00001097          	auipc	ra,0x1
    8000196a:	5a8080e7          	jalr	1448(ra) # 80002f0e <usertrapret>
}
    8000196e:	60a2                	ld	ra,8(sp)
    80001970:	6402                	ld	s0,0(sp)
    80001972:	0141                	addi	sp,sp,16
    80001974:	8082                	ret
    first = 0;
    80001976:	00007797          	auipc	a5,0x7
    8000197a:	ec07ad23          	sw	zero,-294(a5) # 80008850 <first.1708>
    fsinit(ROOTDEV);
    8000197e:	4505                	li	a0,1
    80001980:	00002097          	auipc	ra,0x2
    80001984:	34c080e7          	jalr	844(ra) # 80003ccc <fsinit>
    80001988:	bff9                	j	80001966 <forkret+0x22>

000000008000198a <allocpid>:
allocpid() {
    8000198a:	1101                	addi	sp,sp,-32
    8000198c:	ec06                	sd	ra,24(sp)
    8000198e:	e822                	sd	s0,16(sp)
    80001990:	e426                	sd	s1,8(sp)
    80001992:	e04a                	sd	s2,0(sp)
    80001994:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001996:	00007917          	auipc	s2,0x7
    8000199a:	ebe90913          	addi	s2,s2,-322 # 80008854 <nextpid>
    8000199e:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid,pid,pid+1)!=0);
    800019a2:	0014861b          	addiw	a2,s1,1
    800019a6:	85a6                	mv	a1,s1
    800019a8:	854a                	mv	a0,s2
    800019aa:	00005097          	auipc	ra,0x5
    800019ae:	12c080e7          	jalr	300(ra) # 80006ad6 <cas>
    800019b2:	f575                	bnez	a0,8000199e <allocpid+0x14>
}
    800019b4:	8526                	mv	a0,s1
    800019b6:	60e2                	ld	ra,24(sp)
    800019b8:	6442                	ld	s0,16(sp)
    800019ba:	64a2                	ld	s1,8(sp)
    800019bc:	6902                	ld	s2,0(sp)
    800019be:	6105                	addi	sp,sp,32
    800019c0:	8082                	ret

00000000800019c2 <proc_pagetable>:
{
    800019c2:	1101                	addi	sp,sp,-32
    800019c4:	ec06                	sd	ra,24(sp)
    800019c6:	e822                	sd	s0,16(sp)
    800019c8:	e426                	sd	s1,8(sp)
    800019ca:	e04a                	sd	s2,0(sp)
    800019cc:	1000                	addi	s0,sp,32
    800019ce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	96a080e7          	jalr	-1686(ra) # 8000133a <uvmcreate>
    800019d8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019da:	c121                	beqz	a0,80001a1a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019dc:	4729                	li	a4,10
    800019de:	00005697          	auipc	a3,0x5
    800019e2:	62268693          	addi	a3,a3,1570 # 80007000 <_trampoline>
    800019e6:	6605                	lui	a2,0x1
    800019e8:	040005b7          	lui	a1,0x4000
    800019ec:	15fd                	addi	a1,a1,-1
    800019ee:	05b2                	slli	a1,a1,0xc
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	6c0080e7          	jalr	1728(ra) # 800010b0 <mappages>
    800019f8:	02054863          	bltz	a0,80001a28 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800019fc:	4719                	li	a4,6
    800019fe:	08093683          	ld	a3,128(s2)
    80001a02:	6605                	lui	a2,0x1
    80001a04:	020005b7          	lui	a1,0x2000
    80001a08:	15fd                	addi	a1,a1,-1
    80001a0a:	05b6                	slli	a1,a1,0xd
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	6a2080e7          	jalr	1698(ra) # 800010b0 <mappages>
    80001a16:	02054163          	bltz	a0,80001a38 <proc_pagetable+0x76>
}
    80001a1a:	8526                	mv	a0,s1
    80001a1c:	60e2                	ld	ra,24(sp)
    80001a1e:	6442                	ld	s0,16(sp)
    80001a20:	64a2                	ld	s1,8(sp)
    80001a22:	6902                	ld	s2,0(sp)
    80001a24:	6105                	addi	sp,sp,32
    80001a26:	8082                	ret
    uvmfree(pagetable, 0);
    80001a28:	4581                	li	a1,0
    80001a2a:	8526                	mv	a0,s1
    80001a2c:	00000097          	auipc	ra,0x0
    80001a30:	b0a080e7          	jalr	-1270(ra) # 80001536 <uvmfree>
    return 0;
    80001a34:	4481                	li	s1,0
    80001a36:	b7d5                	j	80001a1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a38:	4681                	li	a3,0
    80001a3a:	4605                	li	a2,1
    80001a3c:	040005b7          	lui	a1,0x4000
    80001a40:	15fd                	addi	a1,a1,-1
    80001a42:	05b2                	slli	a1,a1,0xc
    80001a44:	8526                	mv	a0,s1
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	830080e7          	jalr	-2000(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a4e:	4581                	li	a1,0
    80001a50:	8526                	mv	a0,s1
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	ae4080e7          	jalr	-1308(ra) # 80001536 <uvmfree>
    return 0;
    80001a5a:	4481                	li	s1,0
    80001a5c:	bf7d                	j	80001a1a <proc_pagetable+0x58>

0000000080001a5e <proc_freepagetable>:
{
    80001a5e:	1101                	addi	sp,sp,-32
    80001a60:	ec06                	sd	ra,24(sp)
    80001a62:	e822                	sd	s0,16(sp)
    80001a64:	e426                	sd	s1,8(sp)
    80001a66:	e04a                	sd	s2,0(sp)
    80001a68:	1000                	addi	s0,sp,32
    80001a6a:	84aa                	mv	s1,a0
    80001a6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a6e:	4681                	li	a3,0
    80001a70:	4605                	li	a2,1
    80001a72:	040005b7          	lui	a1,0x4000
    80001a76:	15fd                	addi	a1,a1,-1
    80001a78:	05b2                	slli	a1,a1,0xc
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	7fc080e7          	jalr	2044(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a82:	4681                	li	a3,0
    80001a84:	4605                	li	a2,1
    80001a86:	020005b7          	lui	a1,0x2000
    80001a8a:	15fd                	addi	a1,a1,-1
    80001a8c:	05b6                	slli	a1,a1,0xd
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	7e6080e7          	jalr	2022(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001a98:	85ca                	mv	a1,s2
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	a9a080e7          	jalr	-1382(ra) # 80001536 <uvmfree>
}
    80001aa4:	60e2                	ld	ra,24(sp)
    80001aa6:	6442                	ld	s0,16(sp)
    80001aa8:	64a2                	ld	s1,8(sp)
    80001aaa:	6902                	ld	s2,0(sp)
    80001aac:	6105                	addi	sp,sp,32
    80001aae:	8082                	ret

0000000080001ab0 <growproc>:
{
    80001ab0:	1101                	addi	sp,sp,-32
    80001ab2:	ec06                	sd	ra,24(sp)
    80001ab4:	e822                	sd	s0,16(sp)
    80001ab6:	e426                	sd	s1,8(sp)
    80001ab8:	e04a                	sd	s2,0(sp)
    80001aba:	1000                	addi	s0,sp,32
    80001abc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001abe:	00000097          	auipc	ra,0x0
    80001ac2:	e48080e7          	jalr	-440(ra) # 80001906 <myproc>
    80001ac6:	892a                	mv	s2,a0
  sz = p->sz;
    80001ac8:	792c                	ld	a1,112(a0)
    80001aca:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ace:	00904f63          	bgtz	s1,80001aec <growproc+0x3c>
  } else if(n < 0){
    80001ad2:	0204cc63          	bltz	s1,80001b0a <growproc+0x5a>
  p->sz = sz;
    80001ad6:	1602                	slli	a2,a2,0x20
    80001ad8:	9201                	srli	a2,a2,0x20
    80001ada:	06c93823          	sd	a2,112(s2)
  return 0;
    80001ade:	4501                	li	a0,0
}
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001aec:	9e25                	addw	a2,a2,s1
    80001aee:	1602                	slli	a2,a2,0x20
    80001af0:	9201                	srli	a2,a2,0x20
    80001af2:	1582                	slli	a1,a1,0x20
    80001af4:	9181                	srli	a1,a1,0x20
    80001af6:	7d28                	ld	a0,120(a0)
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	92a080e7          	jalr	-1750(ra) # 80001422 <uvmalloc>
    80001b00:	0005061b          	sext.w	a2,a0
    80001b04:	fa69                	bnez	a2,80001ad6 <growproc+0x26>
      return -1;
    80001b06:	557d                	li	a0,-1
    80001b08:	bfe1                	j	80001ae0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b0a:	9e25                	addw	a2,a2,s1
    80001b0c:	1602                	slli	a2,a2,0x20
    80001b0e:	9201                	srli	a2,a2,0x20
    80001b10:	1582                	slli	a1,a1,0x20
    80001b12:	9181                	srli	a1,a1,0x20
    80001b14:	7d28                	ld	a0,120(a0)
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	8c4080e7          	jalr	-1852(ra) # 800013da <uvmdealloc>
    80001b1e:	0005061b          	sext.w	a2,a0
    80001b22:	bf55                	j	80001ad6 <growproc+0x26>

0000000080001b24 <sched>:
{
    80001b24:	7179                	addi	sp,sp,-48
    80001b26:	f406                	sd	ra,40(sp)
    80001b28:	f022                	sd	s0,32(sp)
    80001b2a:	ec26                	sd	s1,24(sp)
    80001b2c:	e84a                	sd	s2,16(sp)
    80001b2e:	e44e                	sd	s3,8(sp)
    80001b30:	e052                	sd	s4,0(sp)
    80001b32:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	dd2080e7          	jalr	-558(ra) # 80001906 <myproc>
    80001b3c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	02c080e7          	jalr	44(ra) # 80000b6a <holding>
    80001b46:	c141                	beqz	a0,80001bc6 <sched+0xa2>
    80001b48:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001b4a:	2781                	sext.w	a5,a5
    80001b4c:	21800713          	li	a4,536
    80001b50:	02e787b3          	mul	a5,a5,a4
    80001b54:	00016717          	auipc	a4,0x16
    80001b58:	02c70713          	addi	a4,a4,44 # 80017b80 <cpus>
    80001b5c:	97ba                	add	a5,a5,a4
    80001b5e:	5fb8                	lw	a4,120(a5)
    80001b60:	4785                	li	a5,1
    80001b62:	06f71a63          	bne	a4,a5,80001bd6 <sched+0xb2>
  if(p->state == RUNNING)
    80001b66:	4c98                	lw	a4,24(s1)
    80001b68:	4791                	li	a5,4
    80001b6a:	06f70e63          	beq	a4,a5,80001be6 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001b72:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001b74:	e3c9                	bnez	a5,80001bf6 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b76:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001b78:	00016917          	auipc	s2,0x16
    80001b7c:	00890913          	addi	s2,s2,8 # 80017b80 <cpus>
    80001b80:	2781                	sext.w	a5,a5
    80001b82:	21800993          	li	s3,536
    80001b86:	033787b3          	mul	a5,a5,s3
    80001b8a:	97ca                	add	a5,a5,s2
    80001b8c:	07c7aa03          	lw	s4,124(a5)
    80001b90:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80001b92:	2581                	sext.w	a1,a1
    80001b94:	033585b3          	mul	a1,a1,s3
    80001b98:	05a1                	addi	a1,a1,8
    80001b9a:	95ca                	add	a1,a1,s2
    80001b9c:	08848513          	addi	a0,s1,136
    80001ba0:	00001097          	auipc	ra,0x1
    80001ba4:	2c4080e7          	jalr	708(ra) # 80002e64 <swtch>
    80001ba8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001baa:	2781                	sext.w	a5,a5
    80001bac:	033787b3          	mul	a5,a5,s3
    80001bb0:	993e                	add	s2,s2,a5
    80001bb2:	07492e23          	sw	s4,124(s2)
}
    80001bb6:	70a2                	ld	ra,40(sp)
    80001bb8:	7402                	ld	s0,32(sp)
    80001bba:	64e2                	ld	s1,24(sp)
    80001bbc:	6942                	ld	s2,16(sp)
    80001bbe:	69a2                	ld	s3,8(sp)
    80001bc0:	6a02                	ld	s4,0(sp)
    80001bc2:	6145                	addi	sp,sp,48
    80001bc4:	8082                	ret
    panic("sched p->lock");
    80001bc6:	00006517          	auipc	a0,0x6
    80001bca:	61a50513          	addi	a0,a0,1562 # 800081e0 <digits+0x1a0>
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
    panic("sched locks");
    80001bd6:	00006517          	auipc	a0,0x6
    80001bda:	61a50513          	addi	a0,a0,1562 # 800081f0 <digits+0x1b0>
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>
    panic("sched running");
    80001be6:	00006517          	auipc	a0,0x6
    80001bea:	61a50513          	addi	a0,a0,1562 # 80008200 <digits+0x1c0>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001bf6:	00006517          	auipc	a0,0x6
    80001bfa:	61a50513          	addi	a0,a0,1562 # 80008210 <digits+0x1d0>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	940080e7          	jalr	-1728(ra) # 8000053e <panic>

0000000080001c06 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001c06:	7179                	addi	sp,sp,-48
    80001c08:	f406                	sd	ra,40(sp)
    80001c0a:	f022                	sd	s0,32(sp)
    80001c0c:	ec26                	sd	s1,24(sp)
    80001c0e:	e84a                	sd	s2,16(sp)
    80001c10:	e44e                	sd	s3,8(sp)
    80001c12:	e052                	sd	s4,0(sp)
    80001c14:	1800                	addi	s0,sp,48
    80001c16:	84aa                	mv	s1,a0
    80001c18:	892e                	mv	s2,a1
    80001c1a:	89b2                	mv	s3,a2
    80001c1c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	ce8080e7          	jalr	-792(ra) # 80001906 <myproc>
  if(user_dst){
    80001c26:	c08d                	beqz	s1,80001c48 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80001c28:	86d2                	mv	a3,s4
    80001c2a:	864e                	mv	a2,s3
    80001c2c:	85ca                	mv	a1,s2
    80001c2e:	7d28                	ld	a0,120(a0)
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	a42080e7          	jalr	-1470(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001c38:	70a2                	ld	ra,40(sp)
    80001c3a:	7402                	ld	s0,32(sp)
    80001c3c:	64e2                	ld	s1,24(sp)
    80001c3e:	6942                	ld	s2,16(sp)
    80001c40:	69a2                	ld	s3,8(sp)
    80001c42:	6a02                	ld	s4,0(sp)
    80001c44:	6145                	addi	sp,sp,48
    80001c46:	8082                	ret
    memmove((char *)dst, src, len);
    80001c48:	000a061b          	sext.w	a2,s4
    80001c4c:	85ce                	mv	a1,s3
    80001c4e:	854a                	mv	a0,s2
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	0f0080e7          	jalr	240(ra) # 80000d40 <memmove>
    return 0;
    80001c58:	8526                	mv	a0,s1
    80001c5a:	bff9                	j	80001c38 <either_copyout+0x32>

0000000080001c5c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001c5c:	7179                	addi	sp,sp,-48
    80001c5e:	f406                	sd	ra,40(sp)
    80001c60:	f022                	sd	s0,32(sp)
    80001c62:	ec26                	sd	s1,24(sp)
    80001c64:	e84a                	sd	s2,16(sp)
    80001c66:	e44e                	sd	s3,8(sp)
    80001c68:	e052                	sd	s4,0(sp)
    80001c6a:	1800                	addi	s0,sp,48
    80001c6c:	892a                	mv	s2,a0
    80001c6e:	84ae                	mv	s1,a1
    80001c70:	89b2                	mv	s3,a2
    80001c72:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	c92080e7          	jalr	-878(ra) # 80001906 <myproc>
  if(user_src){
    80001c7c:	c08d                	beqz	s1,80001c9e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80001c7e:	86d2                	mv	a3,s4
    80001c80:	864e                	mv	a2,s3
    80001c82:	85ca                	mv	a1,s2
    80001c84:	7d28                	ld	a0,120(a0)
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	a78080e7          	jalr	-1416(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001c8e:	70a2                	ld	ra,40(sp)
    80001c90:	7402                	ld	s0,32(sp)
    80001c92:	64e2                	ld	s1,24(sp)
    80001c94:	6942                	ld	s2,16(sp)
    80001c96:	69a2                	ld	s3,8(sp)
    80001c98:	6a02                	ld	s4,0(sp)
    80001c9a:	6145                	addi	sp,sp,48
    80001c9c:	8082                	ret
    memmove(dst, (char*)src, len);
    80001c9e:	000a061b          	sext.w	a2,s4
    80001ca2:	85ce                	mv	a1,s3
    80001ca4:	854a                	mv	a0,s2
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	09a080e7          	jalr	154(ra) # 80000d40 <memmove>
    return 0;
    80001cae:	8526                	mv	a0,s1
    80001cb0:	bff9                	j	80001c8e <either_copyin+0x32>

0000000080001cb2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001cb2:	715d                	addi	sp,sp,-80
    80001cb4:	e486                	sd	ra,72(sp)
    80001cb6:	e0a2                	sd	s0,64(sp)
    80001cb8:	fc26                	sd	s1,56(sp)
    80001cba:	f84a                	sd	s2,48(sp)
    80001cbc:	f44e                	sd	s3,40(sp)
    80001cbe:	f052                	sd	s4,32(sp)
    80001cc0:	ec56                	sd	s5,24(sp)
    80001cc2:	e85a                	sd	s6,16(sp)
    80001cc4:	e45e                	sd	s7,8(sp)
    80001cc6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	40050513          	addi	a0,a0,1024 # 800080c8 <digits+0x88>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001cd8:	00010497          	auipc	s1,0x10
    80001cdc:	c2848493          	addi	s1,s1,-984 # 80011900 <proc+0x180>
    80001ce0:	00016917          	auipc	s2,0x16
    80001ce4:	02090913          	addi	s2,s2,32 # 80017d00 <cpus+0x180>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001ce8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001cea:	00006997          	auipc	s3,0x6
    80001cee:	53e98993          	addi	s3,s3,1342 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    80001cf2:	00006a97          	auipc	s5,0x6
    80001cf6:	53ea8a93          	addi	s5,s5,1342 # 80008230 <digits+0x1f0>
    printf("\n");
    80001cfa:	00006a17          	auipc	s4,0x6
    80001cfe:	3cea0a13          	addi	s4,s4,974 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d02:	00006b97          	auipc	s7,0x6
    80001d06:	5deb8b93          	addi	s7,s7,1502 # 800082e0 <states.1747>
    80001d0a:	a00d                	j	80001d2c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80001d0c:	eb06a583          	lw	a1,-336(a3)
    80001d10:	8556                	mv	a0,s5
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	876080e7          	jalr	-1930(ra) # 80000588 <printf>
    printf("\n");
    80001d1a:	8552                	mv	a0,s4
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	86c080e7          	jalr	-1940(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001d24:	19048493          	addi	s1,s1,400
    80001d28:	03248163          	beq	s1,s2,80001d4a <procdump+0x98>
    if(p->state == UNUSED)
    80001d2c:	86a6                	mv	a3,s1
    80001d2e:	e984a783          	lw	a5,-360(s1)
    80001d32:	dbed                	beqz	a5,80001d24 <procdump+0x72>
      state = "???";
    80001d34:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d36:	fcfb6be3          	bltu	s6,a5,80001d0c <procdump+0x5a>
    80001d3a:	1782                	slli	a5,a5,0x20
    80001d3c:	9381                	srli	a5,a5,0x20
    80001d3e:	078e                	slli	a5,a5,0x3
    80001d40:	97de                	add	a5,a5,s7
    80001d42:	6390                	ld	a2,0(a5)
    80001d44:	f661                	bnez	a2,80001d0c <procdump+0x5a>
      state = "???";
    80001d46:	864e                	mv	a2,s3
    80001d48:	b7d1                	j	80001d0c <procdump+0x5a>
  }
}
    80001d4a:	60a6                	ld	ra,72(sp)
    80001d4c:	6406                	ld	s0,64(sp)
    80001d4e:	74e2                	ld	s1,56(sp)
    80001d50:	7942                	ld	s2,48(sp)
    80001d52:	79a2                	ld	s3,40(sp)
    80001d54:	7a02                	ld	s4,32(sp)
    80001d56:	6ae2                	ld	s5,24(sp)
    80001d58:	6b42                	ld	s6,16(sp)
    80001d5a:	6ba2                	ld	s7,8(sp)
    80001d5c:	6161                	addi	sp,sp,80
    80001d5e:	8082                	ret

0000000080001d60 <push>:

//assignment 2
extern void push(struct proc* list_empty_head, int index){
    80001d60:	7139                	addi	sp,sp,-64
    80001d62:	fc06                	sd	ra,56(sp)
    80001d64:	f822                	sd	s0,48(sp)
    80001d66:	f426                	sd	s1,40(sp)
    80001d68:	f04a                	sd	s2,32(sp)
    80001d6a:	ec4e                	sd	s3,24(sp)
    80001d6c:	e852                	sd	s4,16(sp)
    80001d6e:	e456                	sd	s5,8(sp)
    80001d70:	e05a                	sd	s6,0(sp)
    80001d72:	0080                	addi	s0,sp,64
    80001d74:	84aa                	mv	s1,a0
    80001d76:	8a2e                	mv	s4,a1
    struct proc *pred_proc = list_empty_head;
    acquire(&pred_proc->node_lock);
    80001d78:	03850513          	addi	a0,a0,56
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	e68080e7          	jalr	-408(ra) # 80000be4 <acquire>
      if (list_empty_head->next != -1){
    80001d84:	48e8                	lw	a0,84(s1)
    80001d86:	57fd                	li	a5,-1
    80001d88:	02f51463          	bne	a0,a5,80001db0 <push+0x50>
  }
 
  release(&curr_proc->node_lock);
  
  }
    pred_proc->next = index;
    80001d8c:	0544aa23          	sw	s4,84(s1)
  release(&pred_proc->node_lock);
    80001d90:	03848513          	addi	a0,s1,56
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
   
}
    80001d9c:	70e2                	ld	ra,56(sp)
    80001d9e:	7442                	ld	s0,48(sp)
    80001da0:	74a2                	ld	s1,40(sp)
    80001da2:	7902                	ld	s2,32(sp)
    80001da4:	69e2                	ld	s3,24(sp)
    80001da6:	6a42                	ld	s4,16(sp)
    80001da8:	6aa2                	ld	s5,8(sp)
    80001daa:	6b02                	ld	s6,0(sp)
    80001dac:	6121                	addi	sp,sp,64
    80001dae:	8082                	ret
    struct proc* curr_proc= &proc[pred_proc->next]; 
    80001db0:	19000793          	li	a5,400
    80001db4:	02f50533          	mul	a0,a0,a5
    80001db8:	00010797          	auipc	a5,0x10
    80001dbc:	9c878793          	addi	a5,a5,-1592 # 80011780 <proc>
    80001dc0:	00f50933          	add	s2,a0,a5
    acquire(&curr_proc->node_lock); 
    80001dc4:	03850513          	addi	a0,a0,56
    80001dc8:	953e                	add	a0,a0,a5
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	e1a080e7          	jalr	-486(ra) # 80000be4 <acquire>
    while (pred_proc->next!=-1 ){
    80001dd2:	48f8                	lw	a4,84(s1)
    80001dd4:	57fd                	li	a5,-1
    80001dd6:	04f70163          	beq	a4,a5,80001e18 <push+0xb8>
    80001dda:	19000b13          	li	s6,400
        curr_proc = &proc[curr_proc->next];
    80001dde:	00010997          	auipc	s3,0x10
    80001de2:	9a298993          	addi	s3,s3,-1630 # 80011780 <proc>
    while (pred_proc->next!=-1 ){
    80001de6:	5afd                	li	s5,-1
        release(&pred_proc->node_lock);
    80001de8:	03848513          	addi	a0,s1,56
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	eac080e7          	jalr	-340(ra) # 80000c98 <release>
        curr_proc = &proc[curr_proc->next];
    80001df4:	05492783          	lw	a5,84(s2)
    80001df8:	036787b3          	mul	a5,a5,s6
    80001dfc:	84ca                	mv	s1,s2
    80001dfe:	01378933          	add	s2,a5,s3
        acquire(&curr_proc->node_lock); 
    80001e02:	03878793          	addi	a5,a5,56
    80001e06:	00f98533          	add	a0,s3,a5
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	dda080e7          	jalr	-550(ra) # 80000be4 <acquire>
    while (pred_proc->next!=-1 ){
    80001e12:	48fc                	lw	a5,84(s1)
    80001e14:	fd579ae3          	bne	a5,s5,80001de8 <push+0x88>
  release(&curr_proc->node_lock);
    80001e18:	03890513          	addi	a0,s2,56
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e7c080e7          	jalr	-388(ra) # 80000c98 <release>
    80001e24:	b7a5                	j	80001d8c <push+0x2c>

0000000080001e26 <procinit>:
{
    80001e26:	711d                	addi	sp,sp,-96
    80001e28:	ec86                	sd	ra,88(sp)
    80001e2a:	e8a2                	sd	s0,80(sp)
    80001e2c:	e4a6                	sd	s1,72(sp)
    80001e2e:	e0ca                	sd	s2,64(sp)
    80001e30:	fc4e                	sd	s3,56(sp)
    80001e32:	f852                	sd	s4,48(sp)
    80001e34:	f456                	sd	s5,40(sp)
    80001e36:	f05a                	sd	s6,32(sp)
    80001e38:	ec5e                	sd	s7,24(sp)
    80001e3a:	e862                	sd	s8,16(sp)
    80001e3c:	e466                	sd	s9,8(sp)
    80001e3e:	e06a                	sd	s10,0(sp)
    80001e40:	1080                	addi	s0,sp,96
   unused_list_head.index = -1; 
    80001e42:	0000f797          	auipc	a5,0xf
    80001e46:	45e78793          	addi	a5,a5,1118 # 800112a0 <unused_list_head>
    80001e4a:	577d                	li	a4,-1
    80001e4c:	cbb8                	sw	a4,80(a5)
   unused_list_head.next = -1;
    80001e4e:	cbf8                	sw	a4,84(a5)
   sleeping_list_head.index = -1;
    80001e50:	1ee7a023          	sw	a4,480(a5)
   sleeping_list_head.next = -1;
    80001e54:	1ee7a223          	sw	a4,484(a5)
   zombie_list_head.index = -1;
    80001e58:	36e7a823          	sw	a4,880(a5)
   zombie_list_head.next = -1;
    80001e5c:	36e7aa23          	sw	a4,884(a5)
   for(c = cpus; c < &cpus[NCPU]; c++) {
    80001e60:	00016797          	auipc	a5,0x16
    80001e64:	d2078793          	addi	a5,a5,-736 # 80017b80 <cpus>
   c->num_of_proc=__INT_MAX__; //new
    80001e68:	800006b7          	lui	a3,0x80000
    80001e6c:	fff6c693          	not	a3,a3
   for(c = cpus; c < &cpus[NCPU]; c++) {
    80001e70:	00017617          	auipc	a2,0x17
    80001e74:	dd060613          	addi	a2,a2,-560 # 80018c40 <tickslock>
   c->runnable_list_head.index=-1;
    80001e78:	0ce7a823          	sw	a4,208(a5)
   c->runnable_list_head.next=-1;
    80001e7c:	0ce7aa23          	sw	a4,212(a5)
   c->num_of_proc=__INT_MAX__; //new
    80001e80:	20d7b823          	sd	a3,528(a5)
   for(c = cpus; c < &cpus[NCPU]; c++) {
    80001e84:	21878793          	addi	a5,a5,536
    80001e88:	fec798e3          	bne	a5,a2,80001e78 <procinit+0x52>
  initlock(&pid_lock, "nextpid");
    80001e8c:	00006597          	auipc	a1,0x6
    80001e90:	3b458593          	addi	a1,a1,948 # 80008240 <digits+0x200>
    80001e94:	00010517          	auipc	a0,0x10
    80001e98:	8bc50513          	addi	a0,a0,-1860 # 80011750 <pid_lock>
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	cb8080e7          	jalr	-840(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ea4:	00006597          	auipc	a1,0x6
    80001ea8:	3a458593          	addi	a1,a1,932 # 80008248 <digits+0x208>
    80001eac:	00010517          	auipc	a0,0x10
    80001eb0:	8bc50513          	addi	a0,a0,-1860 # 80011768 <wait_lock>
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	ca0080e7          	jalr	-864(ra) # 80000b54 <initlock>
  global_index=0;
    80001ebc:	00007797          	auipc	a5,0x7
    80001ec0:	1607a623          	sw	zero,364(a5) # 80009028 <global_index>
  int index = 0;
    80001ec4:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ec6:	00010497          	auipc	s1,0x10
    80001eca:	8ba48493          	addi	s1,s1,-1862 # 80011780 <proc>
      p->next = -1;                         //assignment 2
    80001ece:	5d7d                	li	s10,-1
      global_index++;
    80001ed0:	00007997          	auipc	s3,0x7
    80001ed4:	15898993          	addi	s3,s3,344 # 80009028 <global_index>
      initlock(&p->lock, "proc");
    80001ed8:	00006c97          	auipc	s9,0x6
    80001edc:	380c8c93          	addi	s9,s9,896 # 80008258 <digits+0x218>
       push(&unused_list_head,p->index); //assignemnt2 
    80001ee0:	0000fc17          	auipc	s8,0xf
    80001ee4:	3c0c0c13          	addi	s8,s8,960 # 800112a0 <unused_list_head>
      p->kstack = KSTACK((int) (p - proc));
    80001ee8:	8ba6                	mv	s7,s1
    80001eea:	00006b17          	auipc	s6,0x6
    80001eee:	116b0b13          	addi	s6,s6,278 # 80008000 <etext>
    80001ef2:	04000a37          	lui	s4,0x4000
    80001ef6:	1a7d                	addi	s4,s4,-1
    80001ef8:	0a32                	slli	s4,s4,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001efa:	00016a97          	auipc	s5,0x16
    80001efe:	c86a8a93          	addi	s5,s5,-890 # 80017b80 <cpus>
      p->next = -1;                         //assignment 2
    80001f02:	05a4aa23          	sw	s10,84(s1)
      p->index= index;
    80001f06:	0524a823          	sw	s2,80(s1)
      index++;
    80001f0a:	2905                	addiw	s2,s2,1
      global_index++;
    80001f0c:	0009a783          	lw	a5,0(s3)
    80001f10:	2785                	addiw	a5,a5,1
    80001f12:	00f9a023          	sw	a5,0(s3)
      initlock(&p->lock, "proc");
    80001f16:	85e6                	mv	a1,s9
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	c3a080e7          	jalr	-966(ra) # 80000b54 <initlock>
       push(&unused_list_head,p->index); //assignemnt2 
    80001f22:	48ac                	lw	a1,80(s1)
    80001f24:	8562                	mv	a0,s8
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	e3a080e7          	jalr	-454(ra) # 80001d60 <push>
      p->kstack = KSTACK((int) (p - proc));
    80001f2e:	417487b3          	sub	a5,s1,s7
    80001f32:	8791                	srai	a5,a5,0x4
    80001f34:	000b3703          	ld	a4,0(s6)
    80001f38:	02e787b3          	mul	a5,a5,a4
    80001f3c:	2785                	addiw	a5,a5,1
    80001f3e:	00d7979b          	slliw	a5,a5,0xd
    80001f42:	40fa07b3          	sub	a5,s4,a5
    80001f46:	f4bc                	sd	a5,104(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	19048493          	addi	s1,s1,400
    80001f4c:	fb549be3          	bne	s1,s5,80001f02 <procinit+0xdc>
}
    80001f50:	60e6                	ld	ra,88(sp)
    80001f52:	6446                	ld	s0,80(sp)
    80001f54:	64a6                	ld	s1,72(sp)
    80001f56:	6906                	ld	s2,64(sp)
    80001f58:	79e2                	ld	s3,56(sp)
    80001f5a:	7a42                	ld	s4,48(sp)
    80001f5c:	7aa2                	ld	s5,40(sp)
    80001f5e:	7b02                	ld	s6,32(sp)
    80001f60:	6be2                	ld	s7,24(sp)
    80001f62:	6c42                	ld	s8,16(sp)
    80001f64:	6ca2                	ld	s9,8(sp)
    80001f66:	6d02                	ld	s10,0(sp)
    80001f68:	6125                	addi	sp,sp,96
    80001f6a:	8082                	ret

0000000080001f6c <yield>:
{
    80001f6c:	1101                	addi	sp,sp,-32
    80001f6e:	ec06                	sd	ra,24(sp)
    80001f70:	e822                	sd	s0,16(sp)
    80001f72:	e426                	sd	s1,8(sp)
    80001f74:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	990080e7          	jalr	-1648(ra) # 80001906 <myproc>
    80001f7e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c64080e7          	jalr	-924(ra) # 80000be4 <acquire>
    80001f88:	8792                	mv	a5,tp
    p->state = RUNNABLE;
    80001f8a:	470d                	li	a4,3
    80001f8c:	cc98                	sw	a4,24(s1)
   push(&c->runnable_list_head,p->index);
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	21800513          	li	a0,536
    80001f94:	02a787b3          	mul	a5,a5,a0
    80001f98:	48ac                	lw	a1,80(s1)
    80001f9a:	00016517          	auipc	a0,0x16
    80001f9e:	c6650513          	addi	a0,a0,-922 # 80017c00 <cpus+0x80>
    80001fa2:	953e                	add	a0,a0,a5
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	dbc080e7          	jalr	-580(ra) # 80001d60 <push>
  sched();
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	b78080e7          	jalr	-1160(ra) # 80001b24 <sched>
  release(&p->lock);
    80001fb4:	8526                	mv	a0,s1
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
}
    80001fbe:	60e2                	ld	ra,24(sp)
    80001fc0:	6442                	ld	s0,16(sp)
    80001fc2:	64a2                	ld	s1,8(sp)
    80001fc4:	6105                	addi	sp,sp,32
    80001fc6:	8082                	ret

0000000080001fc8 <sleep>:
{
    80001fc8:	7179                	addi	sp,sp,-48
    80001fca:	f406                	sd	ra,40(sp)
    80001fcc:	f022                	sd	s0,32(sp)
    80001fce:	ec26                	sd	s1,24(sp)
    80001fd0:	e84a                	sd	s2,16(sp)
    80001fd2:	e44e                	sd	s3,8(sp)
    80001fd4:	1800                	addi	s0,sp,48
    80001fd6:	89aa                	mv	s3,a0
    80001fd8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	92c080e7          	jalr	-1748(ra) # 80001906 <myproc>
    80001fe2:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	c00080e7          	jalr	-1024(ra) # 80000be4 <acquire>
  release(lk);
    80001fec:	854a                	mv	a0,s2
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
  p->chan = chan;
    80001ff6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001ffa:	4789                	li	a5,2
    80001ffc:	cc9c                	sw	a5,24(s1)
    80001ffe:	8792                	mv	a5,tp
  int id = r_tp();
    80002000:	ccbc                	sw	a5,88(s1)
  push(&sleeping_list_head,p->index);
    80002002:	48ac                	lw	a1,80(s1)
    80002004:	0000f517          	auipc	a0,0xf
    80002008:	42c50513          	addi	a0,a0,1068 # 80011430 <sleeping_list_head>
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	d54080e7          	jalr	-684(ra) # 80001d60 <push>
  sched();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	b10080e7          	jalr	-1264(ra) # 80001b24 <sched>
  p->chan = 0;
    8000201c:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	c76080e7          	jalr	-906(ra) # 80000c98 <release>
  acquire(lk);
    8000202a:	854a                	mv	a0,s2
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	bb8080e7          	jalr	-1096(ra) # 80000be4 <acquire>
}
    80002034:	70a2                	ld	ra,40(sp)
    80002036:	7402                	ld	s0,32(sp)
    80002038:	64e2                	ld	s1,24(sp)
    8000203a:	6942                	ld	s2,16(sp)
    8000203c:	69a2                	ld	s3,8(sp)
    8000203e:	6145                	addi	sp,sp,48
    80002040:	8082                	ret

0000000080002042 <wakeup>:
{
    80002042:	7159                	addi	sp,sp,-112
    80002044:	f486                	sd	ra,104(sp)
    80002046:	f0a2                	sd	s0,96(sp)
    80002048:	eca6                	sd	s1,88(sp)
    8000204a:	e8ca                	sd	s2,80(sp)
    8000204c:	e4ce                	sd	s3,72(sp)
    8000204e:	e0d2                	sd	s4,64(sp)
    80002050:	fc56                	sd	s5,56(sp)
    80002052:	f85a                	sd	s6,48(sp)
    80002054:	f45e                	sd	s7,40(sp)
    80002056:	f062                	sd	s8,32(sp)
    80002058:	ec66                	sd	s9,24(sp)
    8000205a:	e86a                	sd	s10,16(sp)
    8000205c:	e46e                	sd	s11,8(sp)
    8000205e:	1880                	addi	s0,sp,112
    80002060:	8b2a                	mv	s6,a0
    acquire(&pred_proc->node_lock);
    80002062:	0000f517          	auipc	a0,0xf
    80002066:	40650513          	addi	a0,a0,1030 # 80011468 <sleeping_list_head+0x38>
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b7a080e7          	jalr	-1158(ra) # 80000be4 <acquire>
    if (pred_proc->next != -1){
    80002072:	0000f517          	auipc	a0,0xf
    80002076:	41252503          	lw	a0,1042(a0) # 80011484 <sleeping_list_head+0x54>
    8000207a:	57fd                	li	a5,-1
    struct proc *pred_proc = &sleeping_list_head; 
    8000207c:	0000f997          	auipc	s3,0xf
    80002080:	3b498993          	addi	s3,s3,948 # 80011430 <sleeping_list_head>
    if (pred_proc->next != -1){
    80002084:	02f51763          	bne	a0,a5,800020b2 <wakeup+0x70>
  release(&pred_proc->node_lock);
    80002088:	03898513          	addi	a0,s3,56
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c0c080e7          	jalr	-1012(ra) # 80000c98 <release>
}
    80002094:	70a6                	ld	ra,104(sp)
    80002096:	7406                	ld	s0,96(sp)
    80002098:	64e6                	ld	s1,88(sp)
    8000209a:	6946                	ld	s2,80(sp)
    8000209c:	69a6                	ld	s3,72(sp)
    8000209e:	6a06                	ld	s4,64(sp)
    800020a0:	7ae2                	ld	s5,56(sp)
    800020a2:	7b42                	ld	s6,48(sp)
    800020a4:	7ba2                	ld	s7,40(sp)
    800020a6:	7c02                	ld	s8,32(sp)
    800020a8:	6ce2                	ld	s9,24(sp)
    800020aa:	6d42                	ld	s10,16(sp)
    800020ac:	6da2                	ld	s11,8(sp)
    800020ae:	6165                	addi	sp,sp,112
    800020b0:	8082                	ret
      struct proc* curr_proc= &proc[pred_proc->next];
    800020b2:	19000793          	li	a5,400
    800020b6:	02f50533          	mul	a0,a0,a5
    800020ba:	0000f797          	auipc	a5,0xf
    800020be:	6c678793          	addi	a5,a5,1734 # 80011780 <proc>
    800020c2:	00f504b3          	add	s1,a0,a5
     acquire(&curr_proc->node_lock);
    800020c6:	03850513          	addi	a0,a0,56
    800020ca:	953e                	add	a0,a0,a5
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
      while (curr_proc->next!=-1 ){
    800020d4:	0544a903          	lw	s2,84(s1)
    800020d8:	57fd                	li	a5,-1
    800020da:	10f90163          	beq	s2,a5,800021dc <wakeup+0x19a>
    800020de:	19000c13          	li	s8,400
          curr_proc = &proc[curr_proc->next];
    800020e2:	0000fa17          	auipc	s4,0xf
    800020e6:	69ea0a13          	addi	s4,s4,1694 # 80011780 <proc>
          if(curr_proc->state == SLEEPING && curr_proc->chan==chan){
    800020ea:	4c89                	li	s9,2
            curr_proc->next=-1;
    800020ec:	5dfd                	li	s11,-1
            curr_proc->state = RUNNABLE;
    800020ee:	4d0d                	li	s10,3
      while (curr_proc->next!=-1 ){
    800020f0:	5bfd                	li	s7,-1
    800020f2:	a835                	j	8000212e <wakeup+0xec>
            release(&pred_proc->node_lock);
    800020f4:	03898513          	addi	a0,s3,56
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
            release(&curr_proc->lock);
    80002100:	8556                	mv	a0,s5
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	b96080e7          	jalr	-1130(ra) # 80000c98 <release>
          curr_proc = &proc[curr_proc->next];
    8000210a:	48e8                	lw	a0,84(s1)
    8000210c:	03850533          	mul	a0,a0,s8
    80002110:	01450933          	add	s2,a0,s4
          acquire(&curr_proc->node_lock);
    80002114:	03850513          	addi	a0,a0,56
    80002118:	9552                	add	a0,a0,s4
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	aca080e7          	jalr	-1334(ra) # 80000be4 <acquire>
    80002122:	89a6                	mv	s3,s1
          curr_proc = &proc[curr_proc->next];
    80002124:	84ca                	mv	s1,s2
      while (curr_proc->next!=-1 ){
    80002126:	0544a903          	lw	s2,84(s1)
    8000212a:	0b790d63          	beq	s2,s7,800021e4 <wakeup+0x1a2>
        if(curr_proc!= myproc()) {
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	7d8080e7          	jalr	2008(ra) # 80001906 <myproc>
    80002136:	06a48e63          	beq	s1,a0,800021b2 <wakeup+0x170>
          acquire(&curr_proc->lock);
    8000213a:	8aa6                	mv	s5,s1
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	aa6080e7          	jalr	-1370(ra) # 80000be4 <acquire>
          if(curr_proc->state == SLEEPING && curr_proc->chan==chan){
    80002146:	4c9c                	lw	a5,24(s1)
    80002148:	fb9796e3          	bne	a5,s9,800020f4 <wakeup+0xb2>
    8000214c:	709c                	ld	a5,32(s1)
    8000214e:	fb6793e3          	bne	a5,s6,800020f4 <wakeup+0xb2>
            pred_proc->next=curr_proc->next;
    80002152:	48fc                	lw	a5,84(s1)
    80002154:	04f9aa23          	sw	a5,84(s3)
            curr_proc->next=-1;
    80002158:	05b4aa23          	sw	s11,84(s1)
            curr_proc->state = RUNNABLE;
    8000215c:	01a4ac23          	sw	s10,24(s1)
            push(&cpus[curr_proc->cpu_number].runnable_list_head,curr_proc->index); 
    80002160:	4ca8                	lw	a0,88(s1)
    80002162:	21800793          	li	a5,536
    80002166:	02f50533          	mul	a0,a0,a5
    8000216a:	08050513          	addi	a0,a0,128
    8000216e:	48ac                	lw	a1,80(s1)
    80002170:	00016797          	auipc	a5,0x16
    80002174:	a1078793          	addi	a5,a5,-1520 # 80017b80 <cpus>
    80002178:	953e                	add	a0,a0,a5
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	be6080e7          	jalr	-1050(ra) # 80001d60 <push>
            release(&curr_proc->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b14080e7          	jalr	-1260(ra) # 80000c98 <release>
            release(&curr_proc->node_lock);
    8000218c:	03848513          	addi	a0,s1,56
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
            curr_proc= &proc[next_index];
    80002198:	03890933          	mul	s2,s2,s8
    8000219c:	014904b3          	add	s1,s2,s4
            acquire(&curr_proc->node_lock);
    800021a0:	03890913          	addi	s2,s2,56
    800021a4:	012a0533          	add	a0,s4,s2
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a3c080e7          	jalr	-1476(ra) # 80000be4 <acquire>
    800021b0:	bf9d                	j	80002126 <wakeup+0xe4>
          release(&pred_proc->node_lock);
    800021b2:	03898513          	addi	a0,s3,56
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
          curr_proc = &proc[curr_proc->next];
    800021be:	48e8                	lw	a0,84(s1)
    800021c0:	03850533          	mul	a0,a0,s8
    800021c4:	01450933          	add	s2,a0,s4
          acquire(&curr_proc->node_lock);
    800021c8:	03850513          	addi	a0,a0,56
    800021cc:	9552                	add	a0,a0,s4
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a16080e7          	jalr	-1514(ra) # 80000be4 <acquire>
    800021d6:	89a6                	mv	s3,s1
          curr_proc = &proc[curr_proc->next];
    800021d8:	84ca                	mv	s1,s2
    800021da:	b7b1                	j	80002126 <wakeup+0xe4>
    struct proc *pred_proc = &sleeping_list_head; 
    800021dc:	0000f997          	auipc	s3,0xf
    800021e0:	25498993          	addi	s3,s3,596 # 80011430 <sleeping_list_head>
    if(curr_proc!= myproc()){
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	722080e7          	jalr	1826(ra) # 80001906 <myproc>
    800021ec:	02a48063          	beq	s1,a0,8000220c <wakeup+0x1ca>
      acquire(&curr_proc->lock);
    800021f0:	8926                	mv	s2,s1
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	9f0080e7          	jalr	-1552(ra) # 80000be4 <acquire>
    if(curr_proc->chan==chan){
    800021fc:	709c                	ld	a5,32(s1)
    800021fe:	01678e63          	beq	a5,s6,8000221a <wakeup+0x1d8>
      release(&curr_proc->lock);
    80002202:	854a                	mv	a0,s2
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a94080e7          	jalr	-1388(ra) # 80000c98 <release>
    release(&curr_proc->node_lock);
    8000220c:	03848513          	addi	a0,s1,56
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a88080e7          	jalr	-1400(ra) # 80000c98 <release>
    80002218:	bd85                	j	80002088 <wakeup+0x46>
          pred_proc->next=curr_proc->next;
    8000221a:	48fc                	lw	a5,84(s1)
    8000221c:	04f9aa23          	sw	a5,84(s3)
          curr_proc->next=-1;
    80002220:	57fd                	li	a5,-1
    80002222:	c8fc                	sw	a5,84(s1)
      curr_proc->state = RUNNABLE;
    80002224:	478d                	li	a5,3
    80002226:	cc9c                	sw	a5,24(s1)
            push(&cpus[curr_proc->cpu_number].runnable_list_head,curr_proc->index); 
    80002228:	4cbc                	lw	a5,88(s1)
    8000222a:	21800713          	li	a4,536
    8000222e:	02e787b3          	mul	a5,a5,a4
    80002232:	48ac                	lw	a1,80(s1)
    80002234:	00016517          	auipc	a0,0x16
    80002238:	9cc50513          	addi	a0,a0,-1588 # 80017c00 <cpus+0x80>
    8000223c:	953e                	add	a0,a0,a5
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	b22080e7          	jalr	-1246(ra) # 80001d60 <push>
    80002246:	bf75                	j	80002202 <wakeup+0x1c0>

0000000080002248 <reparent>:
{
    80002248:	7179                	addi	sp,sp,-48
    8000224a:	f406                	sd	ra,40(sp)
    8000224c:	f022                	sd	s0,32(sp)
    8000224e:	ec26                	sd	s1,24(sp)
    80002250:	e84a                	sd	s2,16(sp)
    80002252:	e44e                	sd	s3,8(sp)
    80002254:	e052                	sd	s4,0(sp)
    80002256:	1800                	addi	s0,sp,48
    80002258:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225a:	0000f497          	auipc	s1,0xf
    8000225e:	52648493          	addi	s1,s1,1318 # 80011780 <proc>
      pp->parent = initproc;
    80002262:	00007a17          	auipc	s4,0x7
    80002266:	dcea0a13          	addi	s4,s4,-562 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	00016997          	auipc	s3,0x16
    8000226e:	91698993          	addi	s3,s3,-1770 # 80017b80 <cpus>
    80002272:	a029                	j	8000227c <reparent+0x34>
    80002274:	19048493          	addi	s1,s1,400
    80002278:	01348d63          	beq	s1,s3,80002292 <reparent+0x4a>
    if(pp->parent == p){
    8000227c:	70bc                	ld	a5,96(s1)
    8000227e:	ff279be3          	bne	a5,s2,80002274 <reparent+0x2c>
      pp->parent = initproc;
    80002282:	000a3503          	ld	a0,0(s4)
    80002286:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	dba080e7          	jalr	-582(ra) # 80002042 <wakeup>
    80002290:	b7d5                	j	80002274 <reparent+0x2c>
}
    80002292:	70a2                	ld	ra,40(sp)
    80002294:	7402                	ld	s0,32(sp)
    80002296:	64e2                	ld	s1,24(sp)
    80002298:	6942                	ld	s2,16(sp)
    8000229a:	69a2                	ld	s3,8(sp)
    8000229c:	6a02                	ld	s4,0(sp)
    8000229e:	6145                	addi	sp,sp,48
    800022a0:	8082                	ret

00000000800022a2 <exit>:
{
    800022a2:	7179                	addi	sp,sp,-48
    800022a4:	f406                	sd	ra,40(sp)
    800022a6:	f022                	sd	s0,32(sp)
    800022a8:	ec26                	sd	s1,24(sp)
    800022aa:	e84a                	sd	s2,16(sp)
    800022ac:	e44e                	sd	s3,8(sp)
    800022ae:	e052                	sd	s4,0(sp)
    800022b0:	1800                	addi	s0,sp,48
    800022b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	652080e7          	jalr	1618(ra) # 80001906 <myproc>
    800022bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022be:	00007797          	auipc	a5,0x7
    800022c2:	d727b783          	ld	a5,-654(a5) # 80009030 <initproc>
    800022c6:	0f850493          	addi	s1,a0,248
    800022ca:	17850913          	addi	s2,a0,376
    800022ce:	02a79363          	bne	a5,a0,800022f4 <exit+0x52>
    panic("init exiting");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	f8e50513          	addi	a0,a0,-114 # 80008260 <digits+0x220>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	264080e7          	jalr	612(ra) # 8000053e <panic>
      fileclose(f);
    800022e2:	00003097          	auipc	ra,0x3
    800022e6:	b00080e7          	jalr	-1280(ra) # 80004de2 <fileclose>
      p->ofile[fd] = 0;
    800022ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022ee:	04a1                	addi	s1,s1,8
    800022f0:	01248563          	beq	s1,s2,800022fa <exit+0x58>
    if(p->ofile[fd]){
    800022f4:	6088                	ld	a0,0(s1)
    800022f6:	f575                	bnez	a0,800022e2 <exit+0x40>
    800022f8:	bfdd                	j	800022ee <exit+0x4c>
  begin_op();
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	61c080e7          	jalr	1564(ra) # 80004916 <begin_op>
  iput(p->cwd);
    80002302:	1789b503          	ld	a0,376(s3)
    80002306:	00002097          	auipc	ra,0x2
    8000230a:	df8080e7          	jalr	-520(ra) # 800040fe <iput>
  end_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	688080e7          	jalr	1672(ra) # 80004996 <end_op>
  p->cwd = 0;
    80002316:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    8000231a:	0000f497          	auipc	s1,0xf
    8000231e:	44e48493          	addi	s1,s1,1102 # 80011768 <wait_lock>
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8c0080e7          	jalr	-1856(ra) # 80000be4 <acquire>
  reparent(p);
    8000232c:	854e                	mv	a0,s3
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	f1a080e7          	jalr	-230(ra) # 80002248 <reparent>
  wakeup(p->parent);
    80002336:	0609b503          	ld	a0,96(s3)
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	d08080e7          	jalr	-760(ra) # 80002042 <wakeup>
  acquire(&p->lock);
    80002342:	854e                	mv	a0,s3
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	8a0080e7          	jalr	-1888(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000234c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002350:	4795                	li	a5,5
    80002352:	00f9ac23          	sw	a5,24(s3)
  push(&zombie_list_head,p->index);
    80002356:	0509a583          	lw	a1,80(s3)
    8000235a:	0000f517          	auipc	a0,0xf
    8000235e:	26650513          	addi	a0,a0,614 # 800115c0 <zombie_list_head>
    80002362:	00000097          	auipc	ra,0x0
    80002366:	9fe080e7          	jalr	-1538(ra) # 80001d60 <push>
  release(&wait_lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
  sched();
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	7b0080e7          	jalr	1968(ra) # 80001b24 <sched>
  panic("zombie exit");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	ef450513          	addi	a0,a0,-268 # 80008270 <digits+0x230>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1ba080e7          	jalr	442(ra) # 8000053e <panic>

000000008000238c <pop>:

//assignment 2
extern void pop(struct proc *list_empty_head){
    8000238c:	7139                	addi	sp,sp,-64
    8000238e:	fc06                	sd	ra,56(sp)
    80002390:	f822                	sd	s0,48(sp)
    80002392:	f426                	sd	s1,40(sp)
    80002394:	f04a                	sd	s2,32(sp)
    80002396:	ec4e                	sd	s3,24(sp)
    80002398:	e852                	sd	s4,16(sp)
    8000239a:	e456                	sd	s5,8(sp)
    8000239c:	e05a                	sd	s6,0(sp)
    8000239e:	0080                	addi	s0,sp,64
    800023a0:	84aa                	mv	s1,a0
   acquire(&list_empty_head->node_lock);
    800023a2:	03850a93          	addi	s5,a0,56
    800023a6:	8556                	mv	a0,s5
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  if(list_empty_head->next != -1){ // if list is not empty
    800023b0:	0544aa03          	lw	s4,84(s1)
    800023b4:	57fd                	li	a5,-1
    800023b6:	02fa1163          	bne	s4,a5,800023d8 <pop+0x4c>
      list_empty_head->next=-1;
    }
    curr_proc->next = -1;
    release(&curr_proc->node_lock);
  }
  release(&list_empty_head->node_lock);
    800023ba:	8556                	mv	a0,s5
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
}
    800023c4:	70e2                	ld	ra,56(sp)
    800023c6:	7442                	ld	s0,48(sp)
    800023c8:	74a2                	ld	s1,40(sp)
    800023ca:	7902                	ld	s2,32(sp)
    800023cc:	69e2                	ld	s3,24(sp)
    800023ce:	6a42                	ld	s4,16(sp)
    800023d0:	6aa2                	ld	s5,8(sp)
    800023d2:	6b02                	ld	s6,0(sp)
    800023d4:	6121                	addi	sp,sp,64
    800023d6:	8082                	ret
    acquire(&curr_proc->node_lock);
    800023d8:	19000913          	li	s2,400
    800023dc:	032a09b3          	mul	s3,s4,s2
    800023e0:	03898b13          	addi	s6,s3,56
    800023e4:	0000f917          	auipc	s2,0xf
    800023e8:	39c90913          	addi	s2,s2,924 # 80011780 <proc>
    800023ec:	9b4a                	add	s6,s6,s2
    800023ee:	855a                	mv	a0,s6
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
    if(curr_proc->next!=-1){
    800023f8:	994e                	add	s2,s2,s3
    800023fa:	05492783          	lw	a5,84(s2)
    800023fe:	577d                	li	a4,-1
    80002400:	02e78463          	beq	a5,a4,80002428 <pop+0x9c>
    list_empty_head->next = next_index;//next_proc->index;
    80002404:	c8fc                	sw	a5,84(s1)
    curr_proc->next = -1;
    80002406:	19000793          	li	a5,400
    8000240a:	02fa07b3          	mul	a5,s4,a5
    8000240e:	0000f717          	auipc	a4,0xf
    80002412:	37270713          	addi	a4,a4,882 # 80011780 <proc>
    80002416:	97ba                	add	a5,a5,a4
    80002418:	577d                	li	a4,-1
    8000241a:	cbf8                	sw	a4,84(a5)
    release(&curr_proc->node_lock);
    8000241c:	855a                	mv	a0,s6
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
    80002426:	bf51                	j	800023ba <pop+0x2e>
      list_empty_head->next=-1;
    80002428:	57fd                	li	a5,-1
    8000242a:	c8fc                	sw	a5,84(s1)
    8000242c:	bfe9                	j	80002406 <pop+0x7a>

000000008000242e <scheduler>:
{
    8000242e:	7119                	addi	sp,sp,-128
    80002430:	fc86                	sd	ra,120(sp)
    80002432:	f8a2                	sd	s0,112(sp)
    80002434:	f4a6                	sd	s1,104(sp)
    80002436:	f0ca                	sd	s2,96(sp)
    80002438:	ecce                	sd	s3,88(sp)
    8000243a:	e8d2                	sd	s4,80(sp)
    8000243c:	e4d6                	sd	s5,72(sp)
    8000243e:	e0da                	sd	s6,64(sp)
    80002440:	fc5e                	sd	s7,56(sp)
    80002442:	f862                	sd	s8,48(sp)
    80002444:	f466                	sd	s9,40(sp)
    80002446:	f06a                	sd	s10,32(sp)
    80002448:	ec6e                	sd	s11,24(sp)
    8000244a:	0100                	addi	s0,sp,128
    8000244c:	8712                	mv	a4,tp
  int id = r_tp();
    8000244e:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002450:	00015697          	auipc	a3,0x15
    80002454:	73068693          	addi	a3,a3,1840 # 80017b80 <cpus>
    80002458:	21800793          	li	a5,536
    8000245c:	02f707b3          	mul	a5,a4,a5
    80002460:	00f68633          	add	a2,a3,a5
    80002464:	00063023          	sd	zero,0(a2)
      acquire(&c->runnable_list_head.node_lock);
    80002468:	0b878a93          	addi	s5,a5,184
    8000246c:	9ab6                	add	s5,s5,a3
      pop(&c->runnable_list_head);
    8000246e:	08078c93          	addi	s9,a5,128
    80002472:	9cb6                	add	s9,s9,a3
        swtch(&c->context, &p->context);
    80002474:	07a1                	addi	a5,a5,8
    80002476:	97b6                	add	a5,a5,a3
    80002478:	f8f43423          	sd	a5,-120(s0)
      if(c->runnable_list_head.next!=-1){//assignment2 - if runnable list is not empty.
    8000247c:	8a32                	mv	s4,a2
    8000247e:	5c7d                	li	s8,-1
    80002480:	19000b93          	li	s7,400
      p=&proc[c->runnable_list_head.next];
    80002484:	0000fb17          	auipc	s6,0xf
    80002488:	2fcb0b13          	addi	s6,s6,764 # 80011780 <proc>
      if(p->state == RUNNABLE) {
    8000248c:	4d0d                	li	s10,3
        p->state = RUNNING;
    8000248e:	4d91                	li	s11,4
    80002490:	a821                	j	800024a8 <scheduler+0x7a>
      release( &c->runnable_list_head.node_lock);
    80002492:	8556                	mv	a0,s5
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
    8000249c:	a031                	j	800024a8 <scheduler+0x7a>
      release(&p->lock);
    8000249e:	854a                	mv	a0,s2
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024ac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024b0:	10079073          	csrw	sstatus,a5
      acquire(&c->runnable_list_head.node_lock);
    800024b4:	8556                	mv	a0,s5
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	72e080e7          	jalr	1838(ra) # 80000be4 <acquire>
      if(c->runnable_list_head.next!=-1){//assignment2 - if runnable list is not empty.
    800024be:	0d4a2783          	lw	a5,212(s4)
    800024c2:	fd8788e3          	beq	a5,s8,80002492 <scheduler+0x64>
      release(&c->runnable_list_head.node_lock);
    800024c6:	8556                	mv	a0,s5
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
      p=&proc[c->runnable_list_head.next];
    800024d0:	0d4a2483          	lw	s1,212(s4)
    800024d4:	037489b3          	mul	s3,s1,s7
    800024d8:	01698933          	add	s2,s3,s6
       acquire(&p->lock);
    800024dc:	854a                	mv	a0,s2
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	706080e7          	jalr	1798(ra) # 80000be4 <acquire>
      pop(&c->runnable_list_head);
    800024e6:	8566                	mv	a0,s9
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	ea4080e7          	jalr	-348(ra) # 8000238c <pop>
      if(p->state == RUNNABLE) {
    800024f0:	01892783          	lw	a5,24(s2)
    800024f4:	fba795e3          	bne	a5,s10,8000249e <scheduler+0x70>
  asm volatile("mv %0, tp" : "=r" (x) );
    800024f8:	8792                	mv	a5,tp
  int id = r_tp();
    800024fa:	04f92c23          	sw	a5,88(s2)
        p->state = RUNNING;
    800024fe:	01b92c23          	sw	s11,24(s2)
        c->proc = p;
    80002502:	012a3023          	sd	s2,0(s4)
        swtch(&c->context, &p->context);
    80002506:	08898593          	addi	a1,s3,136
    8000250a:	95da                	add	a1,a1,s6
    8000250c:	f8843503          	ld	a0,-120(s0)
    80002510:	00001097          	auipc	ra,0x1
    80002514:	954080e7          	jalr	-1708(ra) # 80002e64 <swtch>
        c->proc = 0;
    80002518:	000a3023          	sd	zero,0(s4)
    8000251c:	b749                	j	8000249e <scheduler+0x70>

000000008000251e <print_state>:


extern void print_state(){
    8000251e:	1141                	addi	sp,sp,-16
    80002520:	e422                	sd	s0,8(sp)
    80002522:	0800                	addi	s0,sp,16
  // if(sleeping_list_head.next!=-1)
  // printf("sleeping head pid : %d\n",proc[sleeping_list_head.next].pid);
  //   printf("runnable list : ");
  // print_list(&mycpu()->runnable_list_head);
  // printf("\n");
}
    80002524:	6422                	ld	s0,8(sp)
    80002526:	0141                	addi	sp,sp,16
    80002528:	8082                	ret

000000008000252a <print_list>:


extern void print_list(struct proc* list_empty_head){
    8000252a:	7139                	addi	sp,sp,-64
    8000252c:	fc06                	sd	ra,56(sp)
    8000252e:	f822                	sd	s0,48(sp)
    80002530:	f426                	sd	s1,40(sp)
    80002532:	f04a                	sd	s2,32(sp)
    80002534:	ec4e                	sd	s3,24(sp)
    80002536:	e852                	sd	s4,16(sp)
    80002538:	e456                	sd	s5,8(sp)
    8000253a:	e05a                	sd	s6,0(sp)
    8000253c:	0080                	addi	s0,sp,64
    8000253e:	84aa                	mv	s1,a0
  struct proc* curr_proc = list_empty_head;
    acquire(&curr_proc->node_lock);
    80002540:	03850513          	addi	a0,a0,56
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
    struct proc* next_proc= &proc[curr_proc->next]; 
    acquire(&next_proc->node_lock);   
    8000254c:	0544a903          	lw	s2,84(s1)
    80002550:	19000793          	li	a5,400
    80002554:	02f90933          	mul	s2,s2,a5
    80002558:	0000f517          	auipc	a0,0xf
    8000255c:	26050513          	addi	a0,a0,608 # 800117b8 <proc+0x38>
    80002560:	954a                	add	a0,a0,s2
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
    while (curr_proc->next != -1){
    8000256a:	48f0                	lw	a2,84(s1)
    8000256c:	57fd                	li	a5,-1
    8000256e:	0af60063          	beq	a2,a5,8000260e <print_list+0xe4>
      printf("[ %d : %d ] ->", curr_proc->index, curr_proc->next);
    80002572:	00006b17          	auipc	s6,0x6
    80002576:	d0eb0b13          	addi	s6,s6,-754 # 80008280 <digits+0x240>
      
        release(&curr_proc->node_lock);
        curr_proc = &proc[curr_proc->next];
    8000257a:	19000a13          	li	s4,400
    8000257e:	0000f997          	auipc	s3,0xf
    80002582:	20298993          	addi	s3,s3,514 # 80011780 <proc>
    while (curr_proc->next != -1){
    80002586:	5afd                	li	s5,-1
      printf("[ %d : %d ] ->", curr_proc->index, curr_proc->next);
    80002588:	48ac                	lw	a1,80(s1)
    8000258a:	855a                	mv	a0,s6
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	ffc080e7          	jalr	-4(ra) # 80000588 <printf>
        release(&curr_proc->node_lock);
    80002594:	03848513          	addi	a0,s1,56
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
        curr_proc = &proc[curr_proc->next];
    800025a0:	48e4                	lw	s1,84(s1)
    800025a2:	034484b3          	mul	s1,s1,s4
    800025a6:	94ce                	add	s1,s1,s3
        next_proc = &proc[curr_proc->next];
        acquire(&next_proc->node_lock);
    800025a8:	0544a903          	lw	s2,84(s1)
    800025ac:	03490933          	mul	s2,s2,s4
    800025b0:	03890513          	addi	a0,s2,56
    800025b4:	954e                	add	a0,a0,s3
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
    while (curr_proc->next != -1){
    800025be:	48f0                	lw	a2,84(s1)
    800025c0:	fd5614e3          	bne	a2,s5,80002588 <print_list+0x5e>
        next_proc = &proc[curr_proc->next];
    800025c4:	0000f797          	auipc	a5,0xf
    800025c8:	1bc78793          	addi	a5,a5,444 # 80011780 <proc>
    800025cc:	993e                	add	s2,s2,a5

  }
  printf("[ %d : %d ] ->\n", curr_proc->index, curr_proc->next);
    800025ce:	567d                	li	a2,-1
    800025d0:	48ac                	lw	a1,80(s1)
    800025d2:	00006517          	auipc	a0,0x6
    800025d6:	cbe50513          	addi	a0,a0,-834 # 80008290 <digits+0x250>
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	fae080e7          	jalr	-82(ra) # 80000588 <printf>
 
  release(&next_proc->node_lock);
    800025e2:	03890513          	addi	a0,s2,56
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
  release(&curr_proc->node_lock);
    800025ee:	03848513          	addi	a0,s1,56
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
  
}
    800025fa:	70e2                	ld	ra,56(sp)
    800025fc:	7442                	ld	s0,48(sp)
    800025fe:	74a2                	ld	s1,40(sp)
    80002600:	7902                	ld	s2,32(sp)
    80002602:	69e2                	ld	s3,24(sp)
    80002604:	6a42                	ld	s4,16(sp)
    80002606:	6aa2                	ld	s5,8(sp)
    80002608:	6b02                	ld	s6,0(sp)
    8000260a:	6121                	addi	sp,sp,64
    8000260c:	8082                	ret
    struct proc* next_proc= &proc[curr_proc->next]; 
    8000260e:	0000f797          	auipc	a5,0xf
    80002612:	17278793          	addi	a5,a5,370 # 80011780 <proc>
    80002616:	993e                	add	s2,s2,a5
    80002618:	bf5d                	j	800025ce <print_list+0xa4>

000000008000261a <remove>:




extern void remove(struct proc* list_empty_head, int index){
  if (list_empty_head->next != -1){
    8000261a:	4978                	lw	a4,84(a0)
    8000261c:	57fd                	li	a5,-1
    8000261e:	00f71363          	bne	a4,a5,80002624 <remove+0xa>
    80002622:	8082                	ret
extern void remove(struct proc* list_empty_head, int index){
    80002624:	715d                	addi	sp,sp,-80
    80002626:	e486                	sd	ra,72(sp)
    80002628:	e0a2                	sd	s0,64(sp)
    8000262a:	fc26                	sd	s1,56(sp)
    8000262c:	f84a                	sd	s2,48(sp)
    8000262e:	f44e                	sd	s3,40(sp)
    80002630:	f052                	sd	s4,32(sp)
    80002632:	ec56                	sd	s5,24(sp)
    80002634:	e85a                	sd	s6,16(sp)
    80002636:	e45e                	sd	s7,8(sp)
    80002638:	0880                	addi	s0,sp,80
    8000263a:	892a                	mv	s2,a0
    8000263c:	8aae                	mv	s5,a1
    struct proc *pred_proc = list_empty_head;
    acquire(&pred_proc->node_lock);
    8000263e:	03850513          	addi	a0,a0,56
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	5a2080e7          	jalr	1442(ra) # 80000be4 <acquire>
    
    struct proc* curr_proc= &proc[pred_proc->next]; 
    8000264a:	05492783          	lw	a5,84(s2)
    8000264e:	19000513          	li	a0,400
    80002652:	02a787b3          	mul	a5,a5,a0
    80002656:	0000f517          	auipc	a0,0xf
    8000265a:	12a50513          	addi	a0,a0,298 # 80011780 <proc>
    8000265e:	00a784b3          	add	s1,a5,a0
    acquire(&curr_proc->node_lock); 
    80002662:	03878793          	addi	a5,a5,56
    80002666:	953e                	add	a0,a0,a5
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	57c080e7          	jalr	1404(ra) # 80000be4 <acquire>
    while (curr_proc->next!=-1 ){
    80002670:	48fc                	lw	a5,84(s1)
    80002672:	577d                	li	a4,-1
    80002674:	0ae78163          	beq	a5,a4,80002716 <remove+0xfc>
    80002678:	19000b93          	li	s7,400
          return;
      }
      
        release(&pred_proc->node_lock);
        pred_proc = curr_proc;
        curr_proc = &proc[curr_proc->next];
    8000267c:	0000fa17          	auipc	s4,0xf
    80002680:	104a0a13          	addi	s4,s4,260 # 80011780 <proc>
    while (curr_proc->next!=-1 ){
    80002684:	5b7d                	li	s6,-1
    80002686:	a011                	j	8000268a <remove+0x70>
        curr_proc = &proc[curr_proc->next];
    80002688:	84ce                	mv	s1,s3
      if(curr_proc->index==index){
    8000268a:	48b8                	lw	a4,80(s1)
    8000268c:	07570463          	beq	a4,s5,800026f4 <remove+0xda>
        release(&pred_proc->node_lock);
    80002690:	03890513          	addi	a0,s2,56
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
        curr_proc = &proc[curr_proc->next];
    8000269c:	48e8                	lw	a0,84(s1)
    8000269e:	03750533          	mul	a0,a0,s7
    800026a2:	014509b3          	add	s3,a0,s4
        acquire(&curr_proc->node_lock); 
    800026a6:	03850513          	addi	a0,a0,56
    800026aa:	9552                	add	a0,a0,s4
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
    while (curr_proc->next!=-1 ){
    800026b4:	0549a783          	lw	a5,84(s3)
    800026b8:	8926                	mv	s2,s1
    800026ba:	fd6797e3          	bne	a5,s6,80002688 <remove+0x6e>

  }
  if(curr_proc->index==index){
    800026be:	0509a783          	lw	a5,80(s3)
    800026c2:	05578d63          	beq	a5,s5,8000271c <remove+0x102>
  pred_proc->next = -1;
  }
  release(&curr_proc->node_lock);
    800026c6:	03898513          	addi	a0,s3,56
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
  release(&pred_proc->node_lock);
    800026d2:	03848513          	addi	a0,s1,56
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5c2080e7          	jalr	1474(ra) # 80000c98 <release>
  }


}
    800026de:	60a6                	ld	ra,72(sp)
    800026e0:	6406                	ld	s0,64(sp)
    800026e2:	74e2                	ld	s1,56(sp)
    800026e4:	7942                	ld	s2,48(sp)
    800026e6:	79a2                	ld	s3,40(sp)
    800026e8:	7a02                	ld	s4,32(sp)
    800026ea:	6ae2                	ld	s5,24(sp)
    800026ec:	6b42                	ld	s6,16(sp)
    800026ee:	6ba2                	ld	s7,8(sp)
    800026f0:	6161                	addi	sp,sp,80
    800026f2:	8082                	ret
          pred_proc->next=curr_proc->next;
    800026f4:	04f92a23          	sw	a5,84(s2)
          curr_proc->next=-1;
    800026f8:	57fd                	li	a5,-1
    800026fa:	c8fc                	sw	a5,84(s1)
          release(&curr_proc->node_lock);
    800026fc:	03848513          	addi	a0,s1,56
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	598080e7          	jalr	1432(ra) # 80000c98 <release>
          release(&pred_proc->node_lock);
    80002708:	03890513          	addi	a0,s2,56
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	58c080e7          	jalr	1420(ra) # 80000c98 <release>
          return;
    80002714:	b7e9                	j	800026de <remove+0xc4>
    struct proc* curr_proc= &proc[pred_proc->next]; 
    80002716:	89a6                	mv	s3,s1
    struct proc *pred_proc = list_empty_head;
    80002718:	84ca                	mv	s1,s2
    8000271a:	b755                	j	800026be <remove+0xa4>
  pred_proc->next = -1;
    8000271c:	57fd                	li	a5,-1
    8000271e:	c8fc                	sw	a5,84(s1)
    80002720:	b75d                	j	800026c6 <remove+0xac>

0000000080002722 <freeproc>:
{
    80002722:	1101                	addi	sp,sp,-32
    80002724:	ec06                	sd	ra,24(sp)
    80002726:	e822                	sd	s0,16(sp)
    80002728:	e426                	sd	s1,8(sp)
    8000272a:	1000                	addi	s0,sp,32
    8000272c:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000272e:	6148                	ld	a0,128(a0)
    80002730:	c509                	beqz	a0,8000273a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	2c6080e7          	jalr	710(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000273a:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    8000273e:	7ca8                	ld	a0,120(s1)
    80002740:	c511                	beqz	a0,8000274c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002742:	78ac                	ld	a1,112(s1)
    80002744:	fffff097          	auipc	ra,0xfffff
    80002748:	31a080e7          	jalr	794(ra) # 80001a5e <proc_freepagetable>
  p->pagetable = 0;
    8000274c:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80002750:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80002754:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002758:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    8000275c:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80002760:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002764:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002768:	0204a623          	sw	zero,44(s1)
  remove(&zombie_list_head,p->index);
    8000276c:	48ac                	lw	a1,80(s1)
    8000276e:	0000f517          	auipc	a0,0xf
    80002772:	e5250513          	addi	a0,a0,-430 # 800115c0 <zombie_list_head>
    80002776:	00000097          	auipc	ra,0x0
    8000277a:	ea4080e7          	jalr	-348(ra) # 8000261a <remove>
  p->next=-1;
    8000277e:	57fd                	li	a5,-1
    80002780:	c8fc                	sw	a5,84(s1)
  p->cpu_number=-1; // check?
    80002782:	ccbc                	sw	a5,88(s1)
  p->state = UNUSED;
    80002784:	0004ac23          	sw	zero,24(s1)
  push(&unused_list_head,p->index);
    80002788:	48ac                	lw	a1,80(s1)
    8000278a:	0000f517          	auipc	a0,0xf
    8000278e:	b1650513          	addi	a0,a0,-1258 # 800112a0 <unused_list_head>
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	5ce080e7          	jalr	1486(ra) # 80001d60 <push>
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6105                	addi	sp,sp,32
    800027a2:	8082                	ret

00000000800027a4 <allocproc>:
{
    800027a4:	7179                	addi	sp,sp,-48
    800027a6:	f406                	sd	ra,40(sp)
    800027a8:	f022                	sd	s0,32(sp)
    800027aa:	ec26                	sd	s1,24(sp)
    800027ac:	e84a                	sd	s2,16(sp)
    800027ae:	e44e                	sd	s3,8(sp)
    800027b0:	e052                	sd	s4,0(sp)
    800027b2:	1800                	addi	s0,sp,48
acquire(&unused_list_head.node_lock);
    800027b4:	0000f517          	auipc	a0,0xf
    800027b8:	b2450513          	addi	a0,a0,-1244 # 800112d8 <unused_list_head+0x38>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
if(unused_list_head.next==-1){
    800027c4:	0000f717          	auipc	a4,0xf
    800027c8:	b3072703          	lw	a4,-1232(a4) # 800112f4 <unused_list_head+0x54>
    800027cc:	57fd                	li	a5,-1
    800027ce:	0cf70763          	beq	a4,a5,8000289c <allocproc+0xf8>
release(&unused_list_head.node_lock);
    800027d2:	0000f997          	auipc	s3,0xf
    800027d6:	ace98993          	addi	s3,s3,-1330 # 800112a0 <unused_list_head>
    800027da:	0000f517          	auipc	a0,0xf
    800027de:	afe50513          	addi	a0,a0,-1282 # 800112d8 <unused_list_head+0x38>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
p=&proc[unused_list_head.next];
    800027ea:	0549aa03          	lw	s4,84(s3)
    800027ee:	19000913          	li	s2,400
    800027f2:	032a0933          	mul	s2,s4,s2
    800027f6:	0000f497          	auipc	s1,0xf
    800027fa:	f8a48493          	addi	s1,s1,-118 # 80011780 <proc>
    800027fe:	94ca                	add	s1,s1,s2
acquire(&p->lock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	3e2080e7          	jalr	994(ra) # 80000be4 <acquire>
  pop(&unused_list_head);
    8000280a:	854e                	mv	a0,s3
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	b80080e7          	jalr	-1152(ra) # 8000238c <pop>
  p->pid = allocpid();
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	176080e7          	jalr	374(ra) # 8000198a <allocpid>
    8000281c:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000281e:	4785                	li	a5,1
    80002820:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	2d2080e7          	jalr	722(ra) # 80000af4 <kalloc>
    8000282a:	89aa                	mv	s3,a0
    8000282c:	e0c8                	sd	a0,128(s1)
    8000282e:	c149                	beqz	a0,800028b0 <allocproc+0x10c>
  p->pagetable = proc_pagetable(p);
    80002830:	8526                	mv	a0,s1
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	190080e7          	jalr	400(ra) # 800019c2 <proc_pagetable>
    8000283a:	89aa                	mv	s3,a0
    8000283c:	19000793          	li	a5,400
    80002840:	02fa0733          	mul	a4,s4,a5
    80002844:	0000f797          	auipc	a5,0xf
    80002848:	f3c78793          	addi	a5,a5,-196 # 80011780 <proc>
    8000284c:	97ba                	add	a5,a5,a4
    8000284e:	ffa8                	sd	a0,120(a5)
  if(p->pagetable == 0){
    80002850:	cd25                	beqz	a0,800028c8 <allocproc+0x124>
  memset(&p->context, 0, sizeof(p->context));
    80002852:	08890513          	addi	a0,s2,136
    80002856:	0000f997          	auipc	s3,0xf
    8000285a:	f2a98993          	addi	s3,s3,-214 # 80011780 <proc>
    8000285e:	07000613          	li	a2,112
    80002862:	4581                	li	a1,0
    80002864:	954e                	add	a0,a0,s3
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	47a080e7          	jalr	1146(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000286e:	19000793          	li	a5,400
    80002872:	02fa07b3          	mul	a5,s4,a5
    80002876:	97ce                	add	a5,a5,s3
    80002878:	fffff717          	auipc	a4,0xfffff
    8000287c:	0cc70713          	addi	a4,a4,204 # 80001944 <forkret>
    80002880:	e7d8                	sd	a4,136(a5)
  p->context.sp = p->kstack + PGSIZE;
    80002882:	77b8                	ld	a4,104(a5)
    80002884:	6685                	lui	a3,0x1
    80002886:	9736                	add	a4,a4,a3
    80002888:	ebd8                	sd	a4,144(a5)
}
    8000288a:	8526                	mv	a0,s1
    8000288c:	70a2                	ld	ra,40(sp)
    8000288e:	7402                	ld	s0,32(sp)
    80002890:	64e2                	ld	s1,24(sp)
    80002892:	6942                	ld	s2,16(sp)
    80002894:	69a2                	ld	s3,8(sp)
    80002896:	6a02                	ld	s4,0(sp)
    80002898:	6145                	addi	sp,sp,48
    8000289a:	8082                	ret
release(&unused_list_head.node_lock);
    8000289c:	0000f517          	auipc	a0,0xf
    800028a0:	a3c50513          	addi	a0,a0,-1476 # 800112d8 <unused_list_head+0x38>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
  return 0;
    800028ac:	4481                	li	s1,0
    800028ae:	bff1                	j	8000288a <allocproc+0xe6>
    freeproc(p);
    800028b0:	8526                	mv	a0,s1
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	e70080e7          	jalr	-400(ra) # 80002722 <freeproc>
    release(&p->lock);
    800028ba:	8526                	mv	a0,s1
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
    return 0;
    800028c4:	84ce                	mv	s1,s3
    800028c6:	b7d1                	j	8000288a <allocproc+0xe6>
    freeproc(p);
    800028c8:	8526                	mv	a0,s1
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	e58080e7          	jalr	-424(ra) # 80002722 <freeproc>
    release(&p->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	3c4080e7          	jalr	964(ra) # 80000c98 <release>
    return 0;
    800028dc:	84ce                	mv	s1,s3
    800028de:	b775                	j	8000288a <allocproc+0xe6>

00000000800028e0 <userinit>:
{
    800028e0:	1101                	addi	sp,sp,-32
    800028e2:	ec06                	sd	ra,24(sp)
    800028e4:	e822                	sd	s0,16(sp)
    800028e6:	e426                	sd	s1,8(sp)
    800028e8:	1000                	addi	s0,sp,32
  p = allocproc();
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	eba080e7          	jalr	-326(ra) # 800027a4 <allocproc>
    800028f2:	84aa                	mv	s1,a0
  initproc = p;
    800028f4:	00006797          	auipc	a5,0x6
    800028f8:	72a7be23          	sd	a0,1852(a5) # 80009030 <initproc>
    800028fc:	8792                	mv	a5,tp
  int id = r_tp();
    800028fe:	cd3c                	sw	a5,88(a0)
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002900:	03400613          	li	a2,52
    80002904:	00006597          	auipc	a1,0x6
    80002908:	f5c58593          	addi	a1,a1,-164 # 80008860 <initcode>
    8000290c:	7d28                	ld	a0,120(a0)
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	a5a080e7          	jalr	-1446(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002916:	6785                	lui	a5,0x1
    80002918:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    8000291a:	60d8                	ld	a4,128(s1)
    8000291c:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002920:	60d8                	ld	a4,128(s1)
    80002922:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002924:	4641                	li	a2,16
    80002926:	00006597          	auipc	a1,0x6
    8000292a:	97a58593          	addi	a1,a1,-1670 # 800082a0 <digits+0x260>
    8000292e:	18048513          	addi	a0,s1,384
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	500080e7          	jalr	1280(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	97650513          	addi	a0,a0,-1674 # 800082b0 <digits+0x270>
    80002942:	00002097          	auipc	ra,0x2
    80002946:	db8080e7          	jalr	-584(ra) # 800046fa <namei>
    8000294a:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    8000294e:	478d                	li	a5,3
    80002950:	cc9c                	sw	a5,24(s1)
 push(&cpus[p->cpu_number].runnable_list_head,p->index);
    80002952:	4cbc                	lw	a5,88(s1)
    80002954:	21800513          	li	a0,536
    80002958:	02a787b3          	mul	a5,a5,a0
    8000295c:	48ac                	lw	a1,80(s1)
    8000295e:	00015517          	auipc	a0,0x15
    80002962:	2a250513          	addi	a0,a0,674 # 80017c00 <cpus+0x80>
    80002966:	953e                	add	a0,a0,a5
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	3f8080e7          	jalr	1016(ra) # 80001d60 <push>
  release(&p->lock);
    80002970:	8526                	mv	a0,s1
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	326080e7          	jalr	806(ra) # 80000c98 <release>
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret

0000000080002984 <fork>:
{
    80002984:	7179                	addi	sp,sp,-48
    80002986:	f406                	sd	ra,40(sp)
    80002988:	f022                	sd	s0,32(sp)
    8000298a:	ec26                	sd	s1,24(sp)
    8000298c:	e84a                	sd	s2,16(sp)
    8000298e:	e44e                	sd	s3,8(sp)
    80002990:	e052                	sd	s4,0(sp)
    80002992:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	f72080e7          	jalr	-142(ra) # 80001906 <myproc>
    8000299c:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	e06080e7          	jalr	-506(ra) # 800027a4 <allocproc>
    800029a6:	14050863          	beqz	a0,80002af6 <fork+0x172>
    800029aa:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800029ac:	0709b603          	ld	a2,112(s3)
    800029b0:	7d2c                	ld	a1,120(a0)
    800029b2:	0789b503          	ld	a0,120(s3)
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	bb8080e7          	jalr	-1096(ra) # 8000156e <uvmcopy>
    800029be:	04054663          	bltz	a0,80002a0a <fork+0x86>
  np->sz = p->sz;
    800029c2:	0709b783          	ld	a5,112(s3)
    800029c6:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    800029ca:	0809b683          	ld	a3,128(s3)
    800029ce:	87b6                	mv	a5,a3
    800029d0:	08093703          	ld	a4,128(s2)
    800029d4:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800029d8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800029dc:	6788                	ld	a0,8(a5)
    800029de:	6b8c                	ld	a1,16(a5)
    800029e0:	6f90                	ld	a2,24(a5)
    800029e2:	01073023          	sd	a6,0(a4)
    800029e6:	e708                	sd	a0,8(a4)
    800029e8:	eb0c                	sd	a1,16(a4)
    800029ea:	ef10                	sd	a2,24(a4)
    800029ec:	02078793          	addi	a5,a5,32
    800029f0:	02070713          	addi	a4,a4,32
    800029f4:	fed792e3          	bne	a5,a3,800029d8 <fork+0x54>
  np->trapframe->a0 = 0;
    800029f8:	08093783          	ld	a5,128(s2)
    800029fc:	0607b823          	sd	zero,112(a5)
    80002a00:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002a04:	17800a13          	li	s4,376
    80002a08:	a03d                	j	80002a36 <fork+0xb2>
    freeproc(np);
    80002a0a:	854a                	mv	a0,s2
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	d16080e7          	jalr	-746(ra) # 80002722 <freeproc>
    release(&np->lock);
    80002a14:	854a                	mv	a0,s2
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
    return -1;
    80002a1e:	5a7d                	li	s4,-1
    80002a20:	a0d1                	j	80002ae4 <fork+0x160>
      np->ofile[i] = filedup(p->ofile[i]);
    80002a22:	00002097          	auipc	ra,0x2
    80002a26:	36e080e7          	jalr	878(ra) # 80004d90 <filedup>
    80002a2a:	009907b3          	add	a5,s2,s1
    80002a2e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002a30:	04a1                	addi	s1,s1,8
    80002a32:	01448763          	beq	s1,s4,80002a40 <fork+0xbc>
    if(p->ofile[i])
    80002a36:	009987b3          	add	a5,s3,s1
    80002a3a:	6388                	ld	a0,0(a5)
    80002a3c:	f17d                	bnez	a0,80002a22 <fork+0x9e>
    80002a3e:	bfcd                	j	80002a30 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002a40:	1789b503          	ld	a0,376(s3)
    80002a44:	00001097          	auipc	ra,0x1
    80002a48:	4c2080e7          	jalr	1218(ra) # 80003f06 <idup>
    80002a4c:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002a50:	4641                	li	a2,16
    80002a52:	18098593          	addi	a1,s3,384
    80002a56:	18090513          	addi	a0,s2,384
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	3d8080e7          	jalr	984(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002a62:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002a66:	854a                	mv	a0,s2
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a70:	0000f497          	auipc	s1,0xf
    80002a74:	cf848493          	addi	s1,s1,-776 # 80011768 <wait_lock>
    80002a78:	8526                	mv	a0,s1
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	16a080e7          	jalr	362(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a82:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002a86:	8526                	mv	a0,s1
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a90:	854a                	mv	a0,s2
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	152080e7          	jalr	338(ra) # 80000be4 <acquire>
  np->cpu_number = p->cpu_number;
    80002a9a:	0589a503          	lw	a0,88(s3)
    80002a9e:	04a92c23          	sw	a0,88(s2)
  np->next=-1;
    80002aa2:	57fd                	li	a5,-1
    80002aa4:	04f92a23          	sw	a5,84(s2)
  global_index++;
    80002aa8:	00006717          	auipc	a4,0x6
    80002aac:	58070713          	addi	a4,a4,1408 # 80009028 <global_index>
    80002ab0:	431c                	lw	a5,0(a4)
    80002ab2:	2785                	addiw	a5,a5,1
    80002ab4:	c31c                	sw	a5,0(a4)
  np->state = RUNNABLE;
    80002ab6:	478d                	li	a5,3
    80002ab8:	00f92c23          	sw	a5,24(s2)
  push(&cpus[np->cpu_number].runnable_list_head,np->index); 
    80002abc:	21800793          	li	a5,536
    80002ac0:	02f50533          	mul	a0,a0,a5
    80002ac4:	05092583          	lw	a1,80(s2)
    80002ac8:	00015797          	auipc	a5,0x15
    80002acc:	13878793          	addi	a5,a5,312 # 80017c00 <cpus+0x80>
    80002ad0:	953e                	add	a0,a0,a5
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	28e080e7          	jalr	654(ra) # 80001d60 <push>
  release(&np->lock);
    80002ada:	854a                	mv	a0,s2
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	1bc080e7          	jalr	444(ra) # 80000c98 <release>
}
    80002ae4:	8552                	mv	a0,s4
    80002ae6:	70a2                	ld	ra,40(sp)
    80002ae8:	7402                	ld	s0,32(sp)
    80002aea:	64e2                	ld	s1,24(sp)
    80002aec:	6942                	ld	s2,16(sp)
    80002aee:	69a2                	ld	s3,8(sp)
    80002af0:	6a02                	ld	s4,0(sp)
    80002af2:	6145                	addi	sp,sp,48
    80002af4:	8082                	ret
    return -1;
    80002af6:	5a7d                	li	s4,-1
    80002af8:	b7f5                	j	80002ae4 <fork+0x160>

0000000080002afa <wait>:
{
    80002afa:	715d                	addi	sp,sp,-80
    80002afc:	e486                	sd	ra,72(sp)
    80002afe:	e0a2                	sd	s0,64(sp)
    80002b00:	fc26                	sd	s1,56(sp)
    80002b02:	f84a                	sd	s2,48(sp)
    80002b04:	f44e                	sd	s3,40(sp)
    80002b06:	f052                	sd	s4,32(sp)
    80002b08:	ec56                	sd	s5,24(sp)
    80002b0a:	e85a                	sd	s6,16(sp)
    80002b0c:	e45e                	sd	s7,8(sp)
    80002b0e:	e062                	sd	s8,0(sp)
    80002b10:	0880                	addi	s0,sp,80
    80002b12:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	df2080e7          	jalr	-526(ra) # 80001906 <myproc>
    80002b1c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002b1e:	0000f517          	auipc	a0,0xf
    80002b22:	c4a50513          	addi	a0,a0,-950 # 80011768 <wait_lock>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
    havekids = 0;
    80002b2e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002b30:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002b32:	00015997          	auipc	s3,0x15
    80002b36:	04e98993          	addi	s3,s3,78 # 80017b80 <cpus>
        havekids = 1;
    80002b3a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b3c:	0000fc17          	auipc	s8,0xf
    80002b40:	c2cc0c13          	addi	s8,s8,-980 # 80011768 <wait_lock>
    havekids = 0;
    80002b44:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002b46:	0000f497          	auipc	s1,0xf
    80002b4a:	c3a48493          	addi	s1,s1,-966 # 80011780 <proc>
    80002b4e:	a0bd                	j	80002bbc <wait+0xc2>
          pid = np->pid;
    80002b50:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002b54:	000b0e63          	beqz	s6,80002b70 <wait+0x76>
    80002b58:	4691                	li	a3,4
    80002b5a:	02c48613          	addi	a2,s1,44
    80002b5e:	85da                	mv	a1,s6
    80002b60:	07893503          	ld	a0,120(s2)
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	b0e080e7          	jalr	-1266(ra) # 80001672 <copyout>
    80002b6c:	02054563          	bltz	a0,80002b96 <wait+0x9c>
          freeproc(np);
    80002b70:	8526                	mv	a0,s1
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	bb0080e7          	jalr	-1104(ra) # 80002722 <freeproc>
          release(&np->lock);
    80002b7a:	8526                	mv	a0,s1
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	11c080e7          	jalr	284(ra) # 80000c98 <release>
          release(&wait_lock);
    80002b84:	0000f517          	auipc	a0,0xf
    80002b88:	be450513          	addi	a0,a0,-1052 # 80011768 <wait_lock>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	10c080e7          	jalr	268(ra) # 80000c98 <release>
          return pid;
    80002b94:	a09d                	j	80002bfa <wait+0x100>
            release(&np->lock);
    80002b96:	8526                	mv	a0,s1
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	100080e7          	jalr	256(ra) # 80000c98 <release>
            release(&wait_lock);
    80002ba0:	0000f517          	auipc	a0,0xf
    80002ba4:	bc850513          	addi	a0,a0,-1080 # 80011768 <wait_lock>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	0f0080e7          	jalr	240(ra) # 80000c98 <release>
            return -1;
    80002bb0:	59fd                	li	s3,-1
    80002bb2:	a0a1                	j	80002bfa <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002bb4:	19048493          	addi	s1,s1,400
    80002bb8:	03348463          	beq	s1,s3,80002be0 <wait+0xe6>
      if(np->parent == p){
    80002bbc:	70bc                	ld	a5,96(s1)
    80002bbe:	ff279be3          	bne	a5,s2,80002bb4 <wait+0xba>
        acquire(&np->lock);
    80002bc2:	8526                	mv	a0,s1
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	020080e7          	jalr	32(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002bcc:	4c9c                	lw	a5,24(s1)
    80002bce:	f94781e3          	beq	a5,s4,80002b50 <wait+0x56>
        release(&np->lock);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	0c4080e7          	jalr	196(ra) # 80000c98 <release>
        havekids = 1;
    80002bdc:	8756                	mv	a4,s5
    80002bde:	bfd9                	j	80002bb4 <wait+0xba>
    if(!havekids || p->killed){
    80002be0:	c701                	beqz	a4,80002be8 <wait+0xee>
    80002be2:	02892783          	lw	a5,40(s2)
    80002be6:	c79d                	beqz	a5,80002c14 <wait+0x11a>
      release(&wait_lock);
    80002be8:	0000f517          	auipc	a0,0xf
    80002bec:	b8050513          	addi	a0,a0,-1152 # 80011768 <wait_lock>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>
      return -1;
    80002bf8:	59fd                	li	s3,-1
}
    80002bfa:	854e                	mv	a0,s3
    80002bfc:	60a6                	ld	ra,72(sp)
    80002bfe:	6406                	ld	s0,64(sp)
    80002c00:	74e2                	ld	s1,56(sp)
    80002c02:	7942                	ld	s2,48(sp)
    80002c04:	79a2                	ld	s3,40(sp)
    80002c06:	7a02                	ld	s4,32(sp)
    80002c08:	6ae2                	ld	s5,24(sp)
    80002c0a:	6b42                	ld	s6,16(sp)
    80002c0c:	6ba2                	ld	s7,8(sp)
    80002c0e:	6c02                	ld	s8,0(sp)
    80002c10:	6161                	addi	sp,sp,80
    80002c12:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002c14:	85e2                	mv	a1,s8
    80002c16:	854a                	mv	a0,s2
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	3b0080e7          	jalr	944(ra) # 80001fc8 <sleep>
    havekids = 0;
    80002c20:	b715                	j	80002b44 <wait+0x4a>

0000000080002c22 <kill>:
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	e84a                	sd	s2,16(sp)
    80002c2c:	e44e                	sd	s3,8(sp)
    80002c2e:	1800                	addi	s0,sp,48
    80002c30:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002c32:	0000f497          	auipc	s1,0xf
    80002c36:	b4e48493          	addi	s1,s1,-1202 # 80011780 <proc>
    80002c3a:	00015997          	auipc	s3,0x15
    80002c3e:	f4698993          	addi	s3,s3,-186 # 80017b80 <cpus>
    acquire(&p->lock);
    80002c42:	8526                	mv	a0,s1
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	fa0080e7          	jalr	-96(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002c4c:	589c                	lw	a5,48(s1)
    80002c4e:	01278d63          	beq	a5,s2,80002c68 <kill+0x46>
    release(&p->lock);
    80002c52:	8526                	mv	a0,s1
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	044080e7          	jalr	68(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c5c:	19048493          	addi	s1,s1,400
    80002c60:	ff3491e3          	bne	s1,s3,80002c42 <kill+0x20>
  return -1;
    80002c64:	557d                	li	a0,-1
    80002c66:	a829                	j	80002c80 <kill+0x5e>
      p->killed = 1;
    80002c68:	4785                	li	a5,1
    80002c6a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002c6c:	4c98                	lw	a4,24(s1)
    80002c6e:	4789                	li	a5,2
    80002c70:	00f70f63          	beq	a4,a5,80002c8e <kill+0x6c>
      release(&p->lock);
    80002c74:	8526                	mv	a0,s1
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	022080e7          	jalr	34(ra) # 80000c98 <release>
      return 0;
    80002c7e:	4501                	li	a0,0
}
    80002c80:	70a2                	ld	ra,40(sp)
    80002c82:	7402                	ld	s0,32(sp)
    80002c84:	64e2                	ld	s1,24(sp)
    80002c86:	6942                	ld	s2,16(sp)
    80002c88:	69a2                	ld	s3,8(sp)
    80002c8a:	6145                	addi	sp,sp,48
    80002c8c:	8082                	ret
        remove(&sleeping_list_head,p->index);
    80002c8e:	48ac                	lw	a1,80(s1)
    80002c90:	0000e517          	auipc	a0,0xe
    80002c94:	7a050513          	addi	a0,a0,1952 # 80011430 <sleeping_list_head>
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	982080e7          	jalr	-1662(ra) # 8000261a <remove>
        p->state = RUNNABLE;
    80002ca0:	478d                	li	a5,3
    80002ca2:	cc9c                	sw	a5,24(s1)
        push(&cpus[p->cpu_number].runnable_list_head,p->index);   
    80002ca4:	4cbc                	lw	a5,88(s1)
    80002ca6:	21800713          	li	a4,536
    80002caa:	02e787b3          	mul	a5,a5,a4
    80002cae:	48ac                	lw	a1,80(s1)
    80002cb0:	00015517          	auipc	a0,0x15
    80002cb4:	f5050513          	addi	a0,a0,-176 # 80017c00 <cpus+0x80>
    80002cb8:	953e                	add	a0,a0,a5
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	0a6080e7          	jalr	166(ra) # 80001d60 <push>
    80002cc2:	bf4d                	j	80002c74 <kill+0x52>

0000000080002cc4 <set_cpu>:

//assignment2 
int set_cpu(int cpu_num){
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e422                	sd	s0,8(sp)
    80002cc8:	0800                	addi	s0,sp,16
  // struct proc* p = myproc();
  // yield();
  // p->cpu_number = cpu_num;
return 0;
}
    80002cca:	4501                	li	a0,0
    80002ccc:	6422                	ld	s0,8(sp)
    80002cce:	0141                	addi	sp,sp,16
    80002cd0:	8082                	ret

0000000080002cd2 <get_cpu>:

int get_cpu(){
    80002cd2:	1141                	addi	sp,sp,-16
    80002cd4:	e422                	sd	s0,8(sp)
    80002cd6:	0800                	addi	s0,sp,16
    80002cd8:	8512                	mv	a0,tp
  return cpuid();
}
    80002cda:	2501                	sext.w	a0,a0
    80002cdc:	6422                	ld	s0,8(sp)
    80002cde:	0141                	addi	sp,sp,16
    80002ce0:	8082                	ret

0000000080002ce2 <cpu_process_count>:

//assignment2 
int cpu_process_count(int cpu_num){
    80002ce2:	1141                	addi	sp,sp,-16
    80002ce4:	e422                	sd	s0,8(sp)
    80002ce6:	0800                	addi	s0,sp,16
  int ret = cpus[cpu_num].num_of_proc;
    80002ce8:	21800793          	li	a5,536
    80002cec:	02f507b3          	mul	a5,a0,a5
    80002cf0:	00015517          	auipc	a0,0x15
    80002cf4:	e9050513          	addi	a0,a0,-368 # 80017b80 <cpus>
    80002cf8:	953e                	add	a0,a0,a5
  return ret;
}
    80002cfa:	21052503          	lw	a0,528(a0)
    80002cfe:	6422                	ld	s0,8(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <find_min_cpu>:

//assignment2

struct cpu* find_min_cpu(){
    80002d04:	1141                	addi	sp,sp,-16
    80002d06:	e422                	sd	s0,8(sp)
    80002d08:	0800                	addi	s0,sp,16
  struct cpu* c;
  uint64 min_procs= __INT_MAX__;
  struct cpu* c_min;
  for(c_min = cpus ,c = cpus; c < &cpus[NCPU]; c++){
    80002d0a:	00015517          	auipc	a0,0x15
    80002d0e:	e7650513          	addi	a0,a0,-394 # 80017b80 <cpus>
  uint64 min_procs= __INT_MAX__;
    80002d12:	800006b7          	lui	a3,0x80000
    80002d16:	fff6c693          	not	a3,a3
  for(c_min = cpus ,c = cpus; c < &cpus[NCPU]; c++){
    80002d1a:	87aa                	mv	a5,a0
    80002d1c:	00016617          	auipc	a2,0x16
    80002d20:	f2460613          	addi	a2,a2,-220 # 80018c40 <tickslock>
    80002d24:	a029                	j	80002d2e <find_min_cpu+0x2a>
    80002d26:	21878793          	addi	a5,a5,536
    80002d2a:	00c78963          	beq	a5,a2,80002d3c <find_min_cpu+0x38>
    if(c->num_of_proc < min_procs){
    80002d2e:	2107b703          	ld	a4,528(a5)
    80002d32:	fed77ae3          	bgeu	a4,a3,80002d26 <find_min_cpu+0x22>
    80002d36:	853e                	mv	a0,a5
      min_procs = c->num_of_proc;
    80002d38:	86ba                	mv	a3,a4
    80002d3a:	b7f5                	j	80002d26 <find_min_cpu+0x22>
    }
      
  }
  return c_min;

}
    80002d3c:	6422                	ld	s0,8(sp)
    80002d3e:	0141                	addi	sp,sp,16
    80002d40:	8082                	ret

0000000080002d42 <increment_proc_counter>:

int increment_proc_counter(int cpu_num){
    80002d42:	7179                	addi	sp,sp,-48
    80002d44:	f406                	sd	ra,40(sp)
    80002d46:	f022                	sd	s0,32(sp)
    80002d48:	ec26                	sd	s1,24(sp)
    80002d4a:	e84a                	sd	s2,16(sp)
    80002d4c:	e44e                	sd	s3,8(sp)
    80002d4e:	1800                	addi	s0,sp,48
  int proc_counter;
  //assignment 2
  do{
    proc_counter = cpus[cpu_num].num_of_proc;
  }
  while(cas(&cpus[cpu_num].num_of_proc,proc_counter,proc_counter+1)!=0);
    80002d50:	21800913          	li	s2,536
    80002d54:	03250933          	mul	s2,a0,s2
    80002d58:	00015797          	auipc	a5,0x15
    80002d5c:	03878793          	addi	a5,a5,56 # 80017d90 <cpus+0x210>
    80002d60:	993e                	add	s2,s2,a5
    proc_counter = cpus[cpu_num].num_of_proc;
    80002d62:	21800993          	li	s3,536
    80002d66:	03350533          	mul	a0,a0,s3
    80002d6a:	00015997          	auipc	s3,0x15
    80002d6e:	e1698993          	addi	s3,s3,-490 # 80017b80 <cpus>
    80002d72:	99aa                	add	s3,s3,a0
    80002d74:	2109a483          	lw	s1,528(s3)
  while(cas(&cpus[cpu_num].num_of_proc,proc_counter,proc_counter+1)!=0);
    80002d78:	0014861b          	addiw	a2,s1,1
    80002d7c:	85a6                	mv	a1,s1
    80002d7e:	854a                	mv	a0,s2
    80002d80:	00004097          	auipc	ra,0x4
    80002d84:	d56080e7          	jalr	-682(ra) # 80006ad6 <cas>
    80002d88:	f575                	bnez	a0,80002d74 <increment_proc_counter+0x32>
  return proc_counter;

}
    80002d8a:	8526                	mv	a0,s1
    80002d8c:	70a2                	ld	ra,40(sp)
    80002d8e:	7402                	ld	s0,32(sp)
    80002d90:	64e2                	ld	s1,24(sp)
    80002d92:	6942                	ld	s2,16(sp)
    80002d94:	69a2                	ld	s3,8(sp)
    80002d96:	6145                	addi	sp,sp,48
    80002d98:	8082                	ret

0000000080002d9a <still_proc>:

int still_proc(){
    80002d9a:	7139                	addi	sp,sp,-64
    80002d9c:	fc06                	sd	ra,56(sp)
    80002d9e:	f822                	sd	s0,48(sp)
    80002da0:	f426                	sd	s1,40(sp)
    80002da2:	f04a                	sd	s2,32(sp)
    80002da4:	ec4e                	sd	s3,24(sp)
    80002da6:	e852                	sd	s4,16(sp)
    80002da8:	e456                	sd	s5,8(sp)
    80002daa:	0080                	addi	s0,sp,64

int ret;
struct cpu * c;

for(c = cpus; c < &cpus[NCPU]; c++){
    80002dac:	00015497          	auipc	s1,0x15
    80002db0:	dd448493          	addi	s1,s1,-556 # 80017b80 <cpus>
  acquire(&c->runnable_list_head.node_lock);
  if(c->runnable_list_head.next!=-1){
    80002db4:	5a7d                	li	s4,-1
for(c = cpus; c < &cpus[NCPU]; c++){
    80002db6:	00016a97          	auipc	s5,0x16
    80002dba:	e8aa8a93          	addi	s5,s5,-374 # 80018c40 <tickslock>
  acquire(&c->runnable_list_head.node_lock);
    80002dbe:	0b848993          	addi	s3,s1,184
    80002dc2:	854e                	mv	a0,s3
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	e20080e7          	jalr	-480(ra) # 80000be4 <acquire>
  if(c->runnable_list_head.next!=-1){
    80002dcc:	0d44a903          	lw	s2,212(s1)
    80002dd0:	03491863          	bne	s2,s4,80002e00 <still_proc+0x66>
for(c = cpus; c < &cpus[NCPU]; c++){
    80002dd4:	21848493          	addi	s1,s1,536
    80002dd8:	ff5493e3          	bne	s1,s5,80002dbe <still_proc+0x24>
    release(&c->runnable_list_head.node_lock);
   // pop(&c->runnable_list_head);
    return ret;
  }
}
release(&c->runnable_list_head.node_lock);
    80002ddc:	00016517          	auipc	a0,0x16
    80002de0:	f1c50513          	addi	a0,a0,-228 # 80018cf8 <bcache+0xa0>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	eb4080e7          	jalr	-332(ra) # 80000c98 <release>
return -1;

}
    80002dec:	854a                	mv	a0,s2
    80002dee:	70e2                	ld	ra,56(sp)
    80002df0:	7442                	ld	s0,48(sp)
    80002df2:	74a2                	ld	s1,40(sp)
    80002df4:	7902                	ld	s2,32(sp)
    80002df6:	69e2                	ld	s3,24(sp)
    80002df8:	6a42                	ld	s4,16(sp)
    80002dfa:	6aa2                	ld	s5,8(sp)
    80002dfc:	6121                	addi	sp,sp,64
    80002dfe:	8082                	ret
    acquire(&proc[c->runnable_list_head.next].node_lock);
    80002e00:	19000a93          	li	s5,400
    80002e04:	03590533          	mul	a0,s2,s5
    80002e08:	03850513          	addi	a0,a0,56
    80002e0c:	0000fa17          	auipc	s4,0xf
    80002e10:	974a0a13          	addi	s4,s4,-1676 # 80011780 <proc>
    80002e14:	9552                	add	a0,a0,s4
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	dce080e7          	jalr	-562(ra) # 80000be4 <acquire>
    ret = c->runnable_list_head.next;
    80002e1e:	0d44a903          	lw	s2,212(s1)
     if(proc[ret].next!=-1){
    80002e22:	03590ab3          	mul	s5,s2,s5
    80002e26:	9a56                	add	s4,s4,s5
    80002e28:	054a2783          	lw	a5,84(s4)
    80002e2c:	577d                	li	a4,-1
    80002e2e:	02e78763          	beq	a5,a4,80002e5c <still_proc+0xc2>
    c->runnable_list_head.next = next_index;//next_proc->index;
    80002e32:	0cf4aa23          	sw	a5,212(s1)
    release(&proc[ret].node_lock);
    80002e36:	19000793          	li	a5,400
    80002e3a:	02f907b3          	mul	a5,s2,a5
    80002e3e:	0000f517          	auipc	a0,0xf
    80002e42:	97a50513          	addi	a0,a0,-1670 # 800117b8 <proc+0x38>
    80002e46:	953e                	add	a0,a0,a5
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
    release(&c->runnable_list_head.node_lock);
    80002e50:	854e                	mv	a0,s3
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>
    return ret;
    80002e5a:	bf49                	j	80002dec <still_proc+0x52>
      c->runnable_list_head.next=-1;
    80002e5c:	57fd                	li	a5,-1
    80002e5e:	0cf4aa23          	sw	a5,212(s1)
    80002e62:	bfd1                	j	80002e36 <still_proc+0x9c>

0000000080002e64 <swtch>:
    80002e64:	00153023          	sd	ra,0(a0)
    80002e68:	00253423          	sd	sp,8(a0)
    80002e6c:	e900                	sd	s0,16(a0)
    80002e6e:	ed04                	sd	s1,24(a0)
    80002e70:	03253023          	sd	s2,32(a0)
    80002e74:	03353423          	sd	s3,40(a0)
    80002e78:	03453823          	sd	s4,48(a0)
    80002e7c:	03553c23          	sd	s5,56(a0)
    80002e80:	05653023          	sd	s6,64(a0)
    80002e84:	05753423          	sd	s7,72(a0)
    80002e88:	05853823          	sd	s8,80(a0)
    80002e8c:	05953c23          	sd	s9,88(a0)
    80002e90:	07a53023          	sd	s10,96(a0)
    80002e94:	07b53423          	sd	s11,104(a0)
    80002e98:	0005b083          	ld	ra,0(a1)
    80002e9c:	0085b103          	ld	sp,8(a1)
    80002ea0:	6980                	ld	s0,16(a1)
    80002ea2:	6d84                	ld	s1,24(a1)
    80002ea4:	0205b903          	ld	s2,32(a1)
    80002ea8:	0285b983          	ld	s3,40(a1)
    80002eac:	0305ba03          	ld	s4,48(a1)
    80002eb0:	0385ba83          	ld	s5,56(a1)
    80002eb4:	0405bb03          	ld	s6,64(a1)
    80002eb8:	0485bb83          	ld	s7,72(a1)
    80002ebc:	0505bc03          	ld	s8,80(a1)
    80002ec0:	0585bc83          	ld	s9,88(a1)
    80002ec4:	0605bd03          	ld	s10,96(a1)
    80002ec8:	0685bd83          	ld	s11,104(a1)
    80002ecc:	8082                	ret

0000000080002ece <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ece:	1141                	addi	sp,sp,-16
    80002ed0:	e406                	sd	ra,8(sp)
    80002ed2:	e022                	sd	s0,0(sp)
    80002ed4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ed6:	00005597          	auipc	a1,0x5
    80002eda:	43a58593          	addi	a1,a1,1082 # 80008310 <states.1747+0x30>
    80002ede:	00016517          	auipc	a0,0x16
    80002ee2:	d6250513          	addi	a0,a0,-670 # 80018c40 <tickslock>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	c6e080e7          	jalr	-914(ra) # 80000b54 <initlock>
}
    80002eee:	60a2                	ld	ra,8(sp)
    80002ef0:	6402                	ld	s0,0(sp)
    80002ef2:	0141                	addi	sp,sp,16
    80002ef4:	8082                	ret

0000000080002ef6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ef6:	1141                	addi	sp,sp,-16
    80002ef8:	e422                	sd	s0,8(sp)
    80002efa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002efc:	00003797          	auipc	a5,0x3
    80002f00:	50478793          	addi	a5,a5,1284 # 80006400 <kernelvec>
    80002f04:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f08:	6422                	ld	s0,8(sp)
    80002f0a:	0141                	addi	sp,sp,16
    80002f0c:	8082                	ret

0000000080002f0e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f0e:	1141                	addi	sp,sp,-16
    80002f10:	e406                	sd	ra,8(sp)
    80002f12:	e022                	sd	s0,0(sp)
    80002f14:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	9f0080e7          	jalr	-1552(ra) # 80001906 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f24:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f28:	00004617          	auipc	a2,0x4
    80002f2c:	0d860613          	addi	a2,a2,216 # 80007000 <_trampoline>
    80002f30:	00004697          	auipc	a3,0x4
    80002f34:	0d068693          	addi	a3,a3,208 # 80007000 <_trampoline>
    80002f38:	8e91                	sub	a3,a3,a2
    80002f3a:	040007b7          	lui	a5,0x4000
    80002f3e:	17fd                	addi	a5,a5,-1
    80002f40:	07b2                	slli	a5,a5,0xc
    80002f42:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f44:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f48:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f4a:	180026f3          	csrr	a3,satp
    80002f4e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f50:	6158                	ld	a4,128(a0)
    80002f52:	7534                	ld	a3,104(a0)
    80002f54:	6585                	lui	a1,0x1
    80002f56:	96ae                	add	a3,a3,a1
    80002f58:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f5a:	6158                	ld	a4,128(a0)
    80002f5c:	00000697          	auipc	a3,0x0
    80002f60:	13868693          	addi	a3,a3,312 # 80003094 <usertrap>
    80002f64:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f66:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f68:	8692                	mv	a3,tp
    80002f6a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f70:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f74:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f78:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f7c:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f7e:	6f18                	ld	a4,24(a4)
    80002f80:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f84:	7d2c                	ld	a1,120(a0)
    80002f86:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f88:	00004717          	auipc	a4,0x4
    80002f8c:	10870713          	addi	a4,a4,264 # 80007090 <userret>
    80002f90:	8f11                	sub	a4,a4,a2
    80002f92:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f94:	577d                	li	a4,-1
    80002f96:	177e                	slli	a4,a4,0x3f
    80002f98:	8dd9                	or	a1,a1,a4
    80002f9a:	02000537          	lui	a0,0x2000
    80002f9e:	157d                	addi	a0,a0,-1
    80002fa0:	0536                	slli	a0,a0,0xd
    80002fa2:	9782                	jalr	a5
}
    80002fa4:	60a2                	ld	ra,8(sp)
    80002fa6:	6402                	ld	s0,0(sp)
    80002fa8:	0141                	addi	sp,sp,16
    80002faa:	8082                	ret

0000000080002fac <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	e426                	sd	s1,8(sp)
    80002fb4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002fb6:	00016497          	auipc	s1,0x16
    80002fba:	c8a48493          	addi	s1,s1,-886 # 80018c40 <tickslock>
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	c24080e7          	jalr	-988(ra) # 80000be4 <acquire>
  ticks++;
    80002fc8:	00006517          	auipc	a0,0x6
    80002fcc:	07050513          	addi	a0,a0,112 # 80009038 <ticks>
    80002fd0:	411c                	lw	a5,0(a0)
    80002fd2:	2785                	addiw	a5,a5,1
    80002fd4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	06c080e7          	jalr	108(ra) # 80002042 <wakeup>
  release(&tickslock);
    80002fde:	8526                	mv	a0,s1
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	cb8080e7          	jalr	-840(ra) # 80000c98 <release>
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ffc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003000:	00074d63          	bltz	a4,8000301a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003004:	57fd                	li	a5,-1
    80003006:	17fe                	slli	a5,a5,0x3f
    80003008:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000300a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000300c:	06f70363          	beq	a4,a5,80003072 <devintr+0x80>
  }
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret
     (scause & 0xff) == 9){
    8000301a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000301e:	46a5                	li	a3,9
    80003020:	fed792e3          	bne	a5,a3,80003004 <devintr+0x12>
    int irq = plic_claim();
    80003024:	00003097          	auipc	ra,0x3
    80003028:	4e4080e7          	jalr	1252(ra) # 80006508 <plic_claim>
    8000302c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000302e:	47a9                	li	a5,10
    80003030:	02f50763          	beq	a0,a5,8000305e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003034:	4785                	li	a5,1
    80003036:	02f50963          	beq	a0,a5,80003068 <devintr+0x76>
    return 1;
    8000303a:	4505                	li	a0,1
    } else if(irq){
    8000303c:	d8f1                	beqz	s1,80003010 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000303e:	85a6                	mv	a1,s1
    80003040:	00005517          	auipc	a0,0x5
    80003044:	2d850513          	addi	a0,a0,728 # 80008318 <states.1747+0x38>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	540080e7          	jalr	1344(ra) # 80000588 <printf>
      plic_complete(irq);
    80003050:	8526                	mv	a0,s1
    80003052:	00003097          	auipc	ra,0x3
    80003056:	4da080e7          	jalr	1242(ra) # 8000652c <plic_complete>
    return 1;
    8000305a:	4505                	li	a0,1
    8000305c:	bf55                	j	80003010 <devintr+0x1e>
      uartintr();
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	94a080e7          	jalr	-1718(ra) # 800009a8 <uartintr>
    80003066:	b7ed                	j	80003050 <devintr+0x5e>
      virtio_disk_intr();
    80003068:	00004097          	auipc	ra,0x4
    8000306c:	9a4080e7          	jalr	-1628(ra) # 80006a0c <virtio_disk_intr>
    80003070:	b7c5                	j	80003050 <devintr+0x5e>
    if(cpuid() == 0){
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	862080e7          	jalr	-1950(ra) # 800018d4 <cpuid>
    8000307a:	c901                	beqz	a0,8000308a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000307c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003080:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003082:	14479073          	csrw	sip,a5
    return 2;
    80003086:	4509                	li	a0,2
    80003088:	b761                	j	80003010 <devintr+0x1e>
      clockintr();
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	f22080e7          	jalr	-222(ra) # 80002fac <clockintr>
    80003092:	b7ed                	j	8000307c <devintr+0x8a>

0000000080003094 <usertrap>:
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	e04a                	sd	s2,0(sp)
    8000309e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030a0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030a4:	1007f793          	andi	a5,a5,256
    800030a8:	e3ad                	bnez	a5,8000310a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030aa:	00003797          	auipc	a5,0x3
    800030ae:	35678793          	addi	a5,a5,854 # 80006400 <kernelvec>
    800030b2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	850080e7          	jalr	-1968(ra) # 80001906 <myproc>
    800030be:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030c0:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c2:	14102773          	csrr	a4,sepc
    800030c6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030c8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030cc:	47a1                	li	a5,8
    800030ce:	04f71c63          	bne	a4,a5,80003126 <usertrap+0x92>
    if(p->killed)
    800030d2:	551c                	lw	a5,40(a0)
    800030d4:	e3b9                	bnez	a5,8000311a <usertrap+0x86>
    p->trapframe->epc += 4;
    800030d6:	60d8                	ld	a4,128(s1)
    800030d8:	6f1c                	ld	a5,24(a4)
    800030da:	0791                	addi	a5,a5,4
    800030dc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030e2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030e6:	10079073          	csrw	sstatus,a5
    syscall();
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	2e0080e7          	jalr	736(ra) # 800033ca <syscall>
  if(p->killed)
    800030f2:	549c                	lw	a5,40(s1)
    800030f4:	ebc1                	bnez	a5,80003184 <usertrap+0xf0>
  usertrapret();
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	e18080e7          	jalr	-488(ra) # 80002f0e <usertrapret>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("usertrap: not from user mode");
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	22e50513          	addi	a0,a0,558 # 80008338 <states.1747+0x58>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      exit(-1);
    8000311a:	557d                	li	a0,-1
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	186080e7          	jalr	390(ra) # 800022a2 <exit>
    80003124:	bf4d                	j	800030d6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	ecc080e7          	jalr	-308(ra) # 80002ff2 <devintr>
    8000312e:	892a                	mv	s2,a0
    80003130:	c501                	beqz	a0,80003138 <usertrap+0xa4>
  if(p->killed)
    80003132:	549c                	lw	a5,40(s1)
    80003134:	c3a1                	beqz	a5,80003174 <usertrap+0xe0>
    80003136:	a815                	j	8000316a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003138:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000313c:	5890                	lw	a2,48(s1)
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	21a50513          	addi	a0,a0,538 # 80008358 <states.1747+0x78>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	442080e7          	jalr	1090(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000314e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003152:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	23250513          	addi	a0,a0,562 # 80008388 <states.1747+0xa8>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	42a080e7          	jalr	1066(ra) # 80000588 <printf>
    p->killed = 1;
    80003166:	4785                	li	a5,1
    80003168:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000316a:	557d                	li	a0,-1
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	136080e7          	jalr	310(ra) # 800022a2 <exit>
  if(which_dev == 2)
    80003174:	4789                	li	a5,2
    80003176:	f8f910e3          	bne	s2,a5,800030f6 <usertrap+0x62>
    yield();
    8000317a:	fffff097          	auipc	ra,0xfffff
    8000317e:	df2080e7          	jalr	-526(ra) # 80001f6c <yield>
    80003182:	bf95                	j	800030f6 <usertrap+0x62>
  int which_dev = 0;
    80003184:	4901                	li	s2,0
    80003186:	b7d5                	j	8000316a <usertrap+0xd6>

0000000080003188 <kerneltrap>:
{
    80003188:	7179                	addi	sp,sp,-48
    8000318a:	f406                	sd	ra,40(sp)
    8000318c:	f022                	sd	s0,32(sp)
    8000318e:	ec26                	sd	s1,24(sp)
    80003190:	e84a                	sd	s2,16(sp)
    80003192:	e44e                	sd	s3,8(sp)
    80003194:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003196:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000319a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000319e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031a2:	1004f793          	andi	a5,s1,256
    800031a6:	cb85                	beqz	a5,800031d6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031ac:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031ae:	ef85                	bnez	a5,800031e6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031b0:	00000097          	auipc	ra,0x0
    800031b4:	e42080e7          	jalr	-446(ra) # 80002ff2 <devintr>
    800031b8:	cd1d                	beqz	a0,800031f6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031ba:	4789                	li	a5,2
    800031bc:	06f50a63          	beq	a0,a5,80003230 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031c0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031c4:	10049073          	csrw	sstatus,s1
}
    800031c8:	70a2                	ld	ra,40(sp)
    800031ca:	7402                	ld	s0,32(sp)
    800031cc:	64e2                	ld	s1,24(sp)
    800031ce:	6942                	ld	s2,16(sp)
    800031d0:	69a2                	ld	s3,8(sp)
    800031d2:	6145                	addi	sp,sp,48
    800031d4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	1d250513          	addi	a0,a0,466 # 800083a8 <states.1747+0xc8>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	360080e7          	jalr	864(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800031e6:	00005517          	auipc	a0,0x5
    800031ea:	1ea50513          	addi	a0,a0,490 # 800083d0 <states.1747+0xf0>
    800031ee:	ffffd097          	auipc	ra,0xffffd
    800031f2:	350080e7          	jalr	848(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800031f6:	85ce                	mv	a1,s3
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	1f850513          	addi	a0,a0,504 # 800083f0 <states.1747+0x110>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	388080e7          	jalr	904(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003208:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000320c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003210:	00005517          	auipc	a0,0x5
    80003214:	1f050513          	addi	a0,a0,496 # 80008400 <states.1747+0x120>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	370080e7          	jalr	880(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003220:	00005517          	auipc	a0,0x5
    80003224:	1f850513          	addi	a0,a0,504 # 80008418 <states.1747+0x138>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	316080e7          	jalr	790(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	6d6080e7          	jalr	1750(ra) # 80001906 <myproc>
    80003238:	d541                	beqz	a0,800031c0 <kerneltrap+0x38>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	6cc080e7          	jalr	1740(ra) # 80001906 <myproc>
    80003242:	4d18                	lw	a4,24(a0)
    80003244:	4791                	li	a5,4
    80003246:	f6f71de3          	bne	a4,a5,800031c0 <kerneltrap+0x38>
    yield();
    8000324a:	fffff097          	auipc	ra,0xfffff
    8000324e:	d22080e7          	jalr	-734(ra) # 80001f6c <yield>
    80003252:	b7bd                	j	800031c0 <kerneltrap+0x38>

0000000080003254 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	1000                	addi	s0,sp,32
    8000325e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	6a6080e7          	jalr	1702(ra) # 80001906 <myproc>
  switch (n) {
    80003268:	4795                	li	a5,5
    8000326a:	0497e163          	bltu	a5,s1,800032ac <argraw+0x58>
    8000326e:	048a                	slli	s1,s1,0x2
    80003270:	00005717          	auipc	a4,0x5
    80003274:	1e070713          	addi	a4,a4,480 # 80008450 <states.1747+0x170>
    80003278:	94ba                	add	s1,s1,a4
    8000327a:	409c                	lw	a5,0(s1)
    8000327c:	97ba                	add	a5,a5,a4
    8000327e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003280:	615c                	ld	a5,128(a0)
    80003282:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret
    return p->trapframe->a1;
    8000328e:	615c                	ld	a5,128(a0)
    80003290:	7fa8                	ld	a0,120(a5)
    80003292:	bfcd                	j	80003284 <argraw+0x30>
    return p->trapframe->a2;
    80003294:	615c                	ld	a5,128(a0)
    80003296:	63c8                	ld	a0,128(a5)
    80003298:	b7f5                	j	80003284 <argraw+0x30>
    return p->trapframe->a3;
    8000329a:	615c                	ld	a5,128(a0)
    8000329c:	67c8                	ld	a0,136(a5)
    8000329e:	b7dd                	j	80003284 <argraw+0x30>
    return p->trapframe->a4;
    800032a0:	615c                	ld	a5,128(a0)
    800032a2:	6bc8                	ld	a0,144(a5)
    800032a4:	b7c5                	j	80003284 <argraw+0x30>
    return p->trapframe->a5;
    800032a6:	615c                	ld	a5,128(a0)
    800032a8:	6fc8                	ld	a0,152(a5)
    800032aa:	bfe9                	j	80003284 <argraw+0x30>
  panic("argraw");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	17c50513          	addi	a0,a0,380 # 80008428 <states.1747+0x148>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	28a080e7          	jalr	650(ra) # 8000053e <panic>

00000000800032bc <fetchaddr>:
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	e04a                	sd	s2,0(sp)
    800032c6:	1000                	addi	s0,sp,32
    800032c8:	84aa                	mv	s1,a0
    800032ca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	63a080e7          	jalr	1594(ra) # 80001906 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800032d4:	793c                	ld	a5,112(a0)
    800032d6:	02f4f863          	bgeu	s1,a5,80003306 <fetchaddr+0x4a>
    800032da:	00848713          	addi	a4,s1,8
    800032de:	02e7e663          	bltu	a5,a4,8000330a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032e2:	46a1                	li	a3,8
    800032e4:	8626                	mv	a2,s1
    800032e6:	85ca                	mv	a1,s2
    800032e8:	7d28                	ld	a0,120(a0)
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	414080e7          	jalr	1044(ra) # 800016fe <copyin>
    800032f2:	00a03533          	snez	a0,a0
    800032f6:	40a00533          	neg	a0,a0
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6902                	ld	s2,0(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret
    return -1;
    80003306:	557d                	li	a0,-1
    80003308:	bfcd                	j	800032fa <fetchaddr+0x3e>
    8000330a:	557d                	li	a0,-1
    8000330c:	b7fd                	j	800032fa <fetchaddr+0x3e>

000000008000330e <fetchstr>:
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	e84a                	sd	s2,16(sp)
    80003318:	e44e                	sd	s3,8(sp)
    8000331a:	1800                	addi	s0,sp,48
    8000331c:	892a                	mv	s2,a0
    8000331e:	84ae                	mv	s1,a1
    80003320:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	5e4080e7          	jalr	1508(ra) # 80001906 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000332a:	86ce                	mv	a3,s3
    8000332c:	864a                	mv	a2,s2
    8000332e:	85a6                	mv	a1,s1
    80003330:	7d28                	ld	a0,120(a0)
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	458080e7          	jalr	1112(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000333a:	00054763          	bltz	a0,80003348 <fetchstr+0x3a>
  return strlen(buf);
    8000333e:	8526                	mv	a0,s1
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	b24080e7          	jalr	-1244(ra) # 80000e64 <strlen>
}
    80003348:	70a2                	ld	ra,40(sp)
    8000334a:	7402                	ld	s0,32(sp)
    8000334c:	64e2                	ld	s1,24(sp)
    8000334e:	6942                	ld	s2,16(sp)
    80003350:	69a2                	ld	s3,8(sp)
    80003352:	6145                	addi	sp,sp,48
    80003354:	8082                	ret

0000000080003356 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003356:	1101                	addi	sp,sp,-32
    80003358:	ec06                	sd	ra,24(sp)
    8000335a:	e822                	sd	s0,16(sp)
    8000335c:	e426                	sd	s1,8(sp)
    8000335e:	1000                	addi	s0,sp,32
    80003360:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003362:	00000097          	auipc	ra,0x0
    80003366:	ef2080e7          	jalr	-270(ra) # 80003254 <argraw>
    8000336a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000336c:	4501                	li	a0,0
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	1000                	addi	s0,sp,32
    80003382:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003384:	00000097          	auipc	ra,0x0
    80003388:	ed0080e7          	jalr	-304(ra) # 80003254 <argraw>
    8000338c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000338e:	4501                	li	a0,0
    80003390:	60e2                	ld	ra,24(sp)
    80003392:	6442                	ld	s0,16(sp)
    80003394:	64a2                	ld	s1,8(sp)
    80003396:	6105                	addi	sp,sp,32
    80003398:	8082                	ret

000000008000339a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	e426                	sd	s1,8(sp)
    800033a2:	e04a                	sd	s2,0(sp)
    800033a4:	1000                	addi	s0,sp,32
    800033a6:	84ae                	mv	s1,a1
    800033a8:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	eaa080e7          	jalr	-342(ra) # 80003254 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033b2:	864a                	mv	a2,s2
    800033b4:	85a6                	mv	a1,s1
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	f58080e7          	jalr	-168(ra) # 8000330e <fetchstr>
}
    800033be:	60e2                	ld	ra,24(sp)
    800033c0:	6442                	ld	s0,16(sp)
    800033c2:	64a2                	ld	s1,8(sp)
    800033c4:	6902                	ld	s2,0(sp)
    800033c6:	6105                	addi	sp,sp,32
    800033c8:	8082                	ret

00000000800033ca <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count, //assignment 2
};

void
syscall(void)
{
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	e426                	sd	s1,8(sp)
    800033d2:	e04a                	sd	s2,0(sp)
    800033d4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	530080e7          	jalr	1328(ra) # 80001906 <myproc>
    800033de:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800033e0:	08053903          	ld	s2,128(a0)
    800033e4:	0a893783          	ld	a5,168(s2)
    800033e8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800033ec:	37fd                	addiw	a5,a5,-1
    800033ee:	475d                	li	a4,23
    800033f0:	00f76f63          	bltu	a4,a5,8000340e <syscall+0x44>
    800033f4:	00369713          	slli	a4,a3,0x3
    800033f8:	00005797          	auipc	a5,0x5
    800033fc:	07078793          	addi	a5,a5,112 # 80008468 <syscalls>
    80003400:	97ba                	add	a5,a5,a4
    80003402:	639c                	ld	a5,0(a5)
    80003404:	c789                	beqz	a5,8000340e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003406:	9782                	jalr	a5
    80003408:	06a93823          	sd	a0,112(s2)
    8000340c:	a839                	j	8000342a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000340e:	18048613          	addi	a2,s1,384
    80003412:	588c                	lw	a1,48(s1)
    80003414:	00005517          	auipc	a0,0x5
    80003418:	01c50513          	addi	a0,a0,28 # 80008430 <states.1747+0x150>
    8000341c:	ffffd097          	auipc	ra,0xffffd
    80003420:	16c080e7          	jalr	364(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003424:	60dc                	ld	a5,128(s1)
    80003426:	577d                	li	a4,-1
    80003428:	fbb8                	sd	a4,112(a5)
  }
}
    8000342a:	60e2                	ld	ra,24(sp)
    8000342c:	6442                	ld	s0,16(sp)
    8000342e:	64a2                	ld	s1,8(sp)
    80003430:	6902                	ld	s2,0(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret

0000000080003436 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003436:	1101                	addi	sp,sp,-32
    80003438:	ec06                	sd	ra,24(sp)
    8000343a:	e822                	sd	s0,16(sp)
    8000343c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000343e:	fec40593          	addi	a1,s0,-20
    80003442:	4501                	li	a0,0
    80003444:	00000097          	auipc	ra,0x0
    80003448:	f12080e7          	jalr	-238(ra) # 80003356 <argint>
    return -1;
    8000344c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000344e:	00054963          	bltz	a0,80003460 <sys_exit+0x2a>
  exit(n);
    80003452:	fec42503          	lw	a0,-20(s0)
    80003456:	fffff097          	auipc	ra,0xfffff
    8000345a:	e4c080e7          	jalr	-436(ra) # 800022a2 <exit>
  return 0;  // not reached
    8000345e:	4781                	li	a5,0
}
    80003460:	853e                	mv	a0,a5
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	6105                	addi	sp,sp,32
    80003468:	8082                	ret

000000008000346a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000346a:	1141                	addi	sp,sp,-16
    8000346c:	e406                	sd	ra,8(sp)
    8000346e:	e022                	sd	s0,0(sp)
    80003470:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	494080e7          	jalr	1172(ra) # 80001906 <myproc>
}
    8000347a:	5908                	lw	a0,48(a0)
    8000347c:	60a2                	ld	ra,8(sp)
    8000347e:	6402                	ld	s0,0(sp)
    80003480:	0141                	addi	sp,sp,16
    80003482:	8082                	ret

0000000080003484 <sys_fork>:

uint64
sys_fork(void)
{
    80003484:	1141                	addi	sp,sp,-16
    80003486:	e406                	sd	ra,8(sp)
    80003488:	e022                	sd	s0,0(sp)
    8000348a:	0800                	addi	s0,sp,16
  return fork();
    8000348c:	fffff097          	auipc	ra,0xfffff
    80003490:	4f8080e7          	jalr	1272(ra) # 80002984 <fork>
}
    80003494:	60a2                	ld	ra,8(sp)
    80003496:	6402                	ld	s0,0(sp)
    80003498:	0141                	addi	sp,sp,16
    8000349a:	8082                	ret

000000008000349c <sys_wait>:

uint64
sys_wait(void)
{
    8000349c:	1101                	addi	sp,sp,-32
    8000349e:	ec06                	sd	ra,24(sp)
    800034a0:	e822                	sd	s0,16(sp)
    800034a2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034a4:	fe840593          	addi	a1,s0,-24
    800034a8:	4501                	li	a0,0
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	ece080e7          	jalr	-306(ra) # 80003378 <argaddr>
    800034b2:	87aa                	mv	a5,a0
    return -1;
    800034b4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800034b6:	0007c863          	bltz	a5,800034c6 <sys_wait+0x2a>
  return wait(p);
    800034ba:	fe843503          	ld	a0,-24(s0)
    800034be:	fffff097          	auipc	ra,0xfffff
    800034c2:	63c080e7          	jalr	1596(ra) # 80002afa <wait>
}
    800034c6:	60e2                	ld	ra,24(sp)
    800034c8:	6442                	ld	s0,16(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret

00000000800034ce <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800034ce:	7179                	addi	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800034d8:	fdc40593          	addi	a1,s0,-36
    800034dc:	4501                	li	a0,0
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e78080e7          	jalr	-392(ra) # 80003356 <argint>
    800034e6:	87aa                	mv	a5,a0
    return -1;
    800034e8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800034ea:	0207c063          	bltz	a5,8000350a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	418080e7          	jalr	1048(ra) # 80001906 <myproc>
    800034f6:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    800034f8:	fdc42503          	lw	a0,-36(s0)
    800034fc:	ffffe097          	auipc	ra,0xffffe
    80003500:	5b4080e7          	jalr	1460(ra) # 80001ab0 <growproc>
    80003504:	00054863          	bltz	a0,80003514 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003508:	8526                	mv	a0,s1
}
    8000350a:	70a2                	ld	ra,40(sp)
    8000350c:	7402                	ld	s0,32(sp)
    8000350e:	64e2                	ld	s1,24(sp)
    80003510:	6145                	addi	sp,sp,48
    80003512:	8082                	ret
    return -1;
    80003514:	557d                	li	a0,-1
    80003516:	bfd5                	j	8000350a <sys_sbrk+0x3c>

0000000080003518 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003518:	7139                	addi	sp,sp,-64
    8000351a:	fc06                	sd	ra,56(sp)
    8000351c:	f822                	sd	s0,48(sp)
    8000351e:	f426                	sd	s1,40(sp)
    80003520:	f04a                	sd	s2,32(sp)
    80003522:	ec4e                	sd	s3,24(sp)
    80003524:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003526:	fcc40593          	addi	a1,s0,-52
    8000352a:	4501                	li	a0,0
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	e2a080e7          	jalr	-470(ra) # 80003356 <argint>
    return -1;
    80003534:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003536:	06054563          	bltz	a0,800035a0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000353a:	00015517          	auipc	a0,0x15
    8000353e:	70650513          	addi	a0,a0,1798 # 80018c40 <tickslock>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	6a2080e7          	jalr	1698(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000354a:	00006917          	auipc	s2,0x6
    8000354e:	aee92903          	lw	s2,-1298(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003552:	fcc42783          	lw	a5,-52(s0)
    80003556:	cf85                	beqz	a5,8000358e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003558:	00015997          	auipc	s3,0x15
    8000355c:	6e898993          	addi	s3,s3,1768 # 80018c40 <tickslock>
    80003560:	00006497          	auipc	s1,0x6
    80003564:	ad848493          	addi	s1,s1,-1320 # 80009038 <ticks>
    if(myproc()->killed){
    80003568:	ffffe097          	auipc	ra,0xffffe
    8000356c:	39e080e7          	jalr	926(ra) # 80001906 <myproc>
    80003570:	551c                	lw	a5,40(a0)
    80003572:	ef9d                	bnez	a5,800035b0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003574:	85ce                	mv	a1,s3
    80003576:	8526                	mv	a0,s1
    80003578:	fffff097          	auipc	ra,0xfffff
    8000357c:	a50080e7          	jalr	-1456(ra) # 80001fc8 <sleep>
  while(ticks - ticks0 < n){
    80003580:	409c                	lw	a5,0(s1)
    80003582:	412787bb          	subw	a5,a5,s2
    80003586:	fcc42703          	lw	a4,-52(s0)
    8000358a:	fce7efe3          	bltu	a5,a4,80003568 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000358e:	00015517          	auipc	a0,0x15
    80003592:	6b250513          	addi	a0,a0,1714 # 80018c40 <tickslock>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	702080e7          	jalr	1794(ra) # 80000c98 <release>
  return 0;
    8000359e:	4781                	li	a5,0
}
    800035a0:	853e                	mv	a0,a5
    800035a2:	70e2                	ld	ra,56(sp)
    800035a4:	7442                	ld	s0,48(sp)
    800035a6:	74a2                	ld	s1,40(sp)
    800035a8:	7902                	ld	s2,32(sp)
    800035aa:	69e2                	ld	s3,24(sp)
    800035ac:	6121                	addi	sp,sp,64
    800035ae:	8082                	ret
      release(&tickslock);
    800035b0:	00015517          	auipc	a0,0x15
    800035b4:	69050513          	addi	a0,a0,1680 # 80018c40 <tickslock>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	6e0080e7          	jalr	1760(ra) # 80000c98 <release>
      return -1;
    800035c0:	57fd                	li	a5,-1
    800035c2:	bff9                	j	800035a0 <sys_sleep+0x88>

00000000800035c4 <sys_kill>:

uint64
sys_kill(void)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800035cc:	fec40593          	addi	a1,s0,-20
    800035d0:	4501                	li	a0,0
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	d84080e7          	jalr	-636(ra) # 80003356 <argint>
    800035da:	87aa                	mv	a5,a0
    return -1;
    800035dc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800035de:	0007c863          	bltz	a5,800035ee <sys_kill+0x2a>
  return kill(pid);
    800035e2:	fec42503          	lw	a0,-20(s0)
    800035e6:	fffff097          	auipc	ra,0xfffff
    800035ea:	63c080e7          	jalr	1596(ra) # 80002c22 <kill>
}
    800035ee:	60e2                	ld	ra,24(sp)
    800035f0:	6442                	ld	s0,16(sp)
    800035f2:	6105                	addi	sp,sp,32
    800035f4:	8082                	ret

00000000800035f6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800035f6:	1101                	addi	sp,sp,-32
    800035f8:	ec06                	sd	ra,24(sp)
    800035fa:	e822                	sd	s0,16(sp)
    800035fc:	e426                	sd	s1,8(sp)
    800035fe:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003600:	00015517          	auipc	a0,0x15
    80003604:	64050513          	addi	a0,a0,1600 # 80018c40 <tickslock>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5dc080e7          	jalr	1500(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003610:	00006497          	auipc	s1,0x6
    80003614:	a284a483          	lw	s1,-1496(s1) # 80009038 <ticks>
  release(&tickslock);
    80003618:	00015517          	auipc	a0,0x15
    8000361c:	62850513          	addi	a0,a0,1576 # 80018c40 <tickslock>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	678080e7          	jalr	1656(ra) # 80000c98 <release>
  return xticks;
}
    80003628:	02049513          	slli	a0,s1,0x20
    8000362c:	9101                	srli	a0,a0,0x20
    8000362e:	60e2                	ld	ra,24(sp)
    80003630:	6442                	ld	s0,16(sp)
    80003632:	64a2                	ld	s1,8(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret

0000000080003638 <sys_set_cpu>:


//assignment2
uint64
sys_set_cpu(void)
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	1000                	addi	s0,sp,32

  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003640:	fec40593          	addi	a1,s0,-20
    80003644:	4501                	li	a0,0
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	d10080e7          	jalr	-752(ra) # 80003356 <argint>
    8000364e:	87aa                	mv	a5,a0
    return -1;
    80003650:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003652:	0007c863          	bltz	a5,80003662 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    80003656:	fec42503          	lw	a0,-20(s0)
    8000365a:	fffff097          	auipc	ra,0xfffff
    8000365e:	66a080e7          	jalr	1642(ra) # 80002cc4 <set_cpu>
}
    80003662:	60e2                	ld	ra,24(sp)
    80003664:	6442                	ld	s0,16(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret

000000008000366a <sys_get_cpu>:


//assignment2
uint64
sys_get_cpu(void)
{
    8000366a:	1141                	addi	sp,sp,-16
    8000366c:	e406                	sd	ra,8(sp)
    8000366e:	e022                	sd	s0,0(sp)
    80003670:	0800                	addi	s0,sp,16
  return get_cpu();
    80003672:	fffff097          	auipc	ra,0xfffff
    80003676:	660080e7          	jalr	1632(ra) # 80002cd2 <get_cpu>

}
    8000367a:	60a2                	ld	ra,8(sp)
    8000367c:	6402                	ld	s0,0(sp)
    8000367e:	0141                	addi	sp,sp,16
    80003680:	8082                	ret

0000000080003682 <sys_cpu_process_count>:

//assignment2
uint64
sys_cpu_process_count(void)
{
    80003682:	1101                	addi	sp,sp,-32
    80003684:	ec06                	sd	ra,24(sp)
    80003686:	e822                	sd	s0,16(sp)
    80003688:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    8000368a:	fec40593          	addi	a1,s0,-20
    8000368e:	4501                	li	a0,0
    80003690:	00000097          	auipc	ra,0x0
    80003694:	cc6080e7          	jalr	-826(ra) # 80003356 <argint>
    80003698:	87aa                	mv	a5,a0
    return -1;
    8000369a:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    8000369c:	0007c863          	bltz	a5,800036ac <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    800036a0:	fec42503          	lw	a0,-20(s0)
    800036a4:	fffff097          	auipc	ra,0xfffff
    800036a8:	63e080e7          	jalr	1598(ra) # 80002ce2 <cpu_process_count>
}
    800036ac:	60e2                	ld	ra,24(sp)
    800036ae:	6442                	ld	s0,16(sp)
    800036b0:	6105                	addi	sp,sp,32
    800036b2:	8082                	ret

00000000800036b4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800036b4:	7179                	addi	sp,sp,-48
    800036b6:	f406                	sd	ra,40(sp)
    800036b8:	f022                	sd	s0,32(sp)
    800036ba:	ec26                	sd	s1,24(sp)
    800036bc:	e84a                	sd	s2,16(sp)
    800036be:	e44e                	sd	s3,8(sp)
    800036c0:	e052                	sd	s4,0(sp)
    800036c2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800036c4:	00005597          	auipc	a1,0x5
    800036c8:	e6c58593          	addi	a1,a1,-404 # 80008530 <syscalls+0xc8>
    800036cc:	00015517          	auipc	a0,0x15
    800036d0:	58c50513          	addi	a0,a0,1420 # 80018c58 <bcache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	480080e7          	jalr	1152(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036dc:	0001d797          	auipc	a5,0x1d
    800036e0:	57c78793          	addi	a5,a5,1404 # 80020c58 <bcache+0x8000>
    800036e4:	0001d717          	auipc	a4,0x1d
    800036e8:	7dc70713          	addi	a4,a4,2012 # 80020ec0 <bcache+0x8268>
    800036ec:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036f0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036f4:	00015497          	auipc	s1,0x15
    800036f8:	57c48493          	addi	s1,s1,1404 # 80018c70 <bcache+0x18>
    b->next = bcache.head.next;
    800036fc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036fe:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003700:	00005a17          	auipc	s4,0x5
    80003704:	e38a0a13          	addi	s4,s4,-456 # 80008538 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003708:	2b893783          	ld	a5,696(s2)
    8000370c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000370e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003712:	85d2                	mv	a1,s4
    80003714:	01048513          	addi	a0,s1,16
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	4bc080e7          	jalr	1212(ra) # 80004bd4 <initsleeplock>
    bcache.head.next->prev = b;
    80003720:	2b893783          	ld	a5,696(s2)
    80003724:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003726:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000372a:	45848493          	addi	s1,s1,1112
    8000372e:	fd349de3          	bne	s1,s3,80003708 <binit+0x54>
  }
}
    80003732:	70a2                	ld	ra,40(sp)
    80003734:	7402                	ld	s0,32(sp)
    80003736:	64e2                	ld	s1,24(sp)
    80003738:	6942                	ld	s2,16(sp)
    8000373a:	69a2                	ld	s3,8(sp)
    8000373c:	6a02                	ld	s4,0(sp)
    8000373e:	6145                	addi	sp,sp,48
    80003740:	8082                	ret

0000000080003742 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003742:	7179                	addi	sp,sp,-48
    80003744:	f406                	sd	ra,40(sp)
    80003746:	f022                	sd	s0,32(sp)
    80003748:	ec26                	sd	s1,24(sp)
    8000374a:	e84a                	sd	s2,16(sp)
    8000374c:	e44e                	sd	s3,8(sp)
    8000374e:	1800                	addi	s0,sp,48
    80003750:	89aa                	mv	s3,a0
    80003752:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003754:	00015517          	auipc	a0,0x15
    80003758:	50450513          	addi	a0,a0,1284 # 80018c58 <bcache>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	488080e7          	jalr	1160(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003764:	0001d497          	auipc	s1,0x1d
    80003768:	7ac4b483          	ld	s1,1964(s1) # 80020f10 <bcache+0x82b8>
    8000376c:	0001d797          	auipc	a5,0x1d
    80003770:	75478793          	addi	a5,a5,1876 # 80020ec0 <bcache+0x8268>
    80003774:	02f48f63          	beq	s1,a5,800037b2 <bread+0x70>
    80003778:	873e                	mv	a4,a5
    8000377a:	a021                	j	80003782 <bread+0x40>
    8000377c:	68a4                	ld	s1,80(s1)
    8000377e:	02e48a63          	beq	s1,a4,800037b2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003782:	449c                	lw	a5,8(s1)
    80003784:	ff379ce3          	bne	a5,s3,8000377c <bread+0x3a>
    80003788:	44dc                	lw	a5,12(s1)
    8000378a:	ff2799e3          	bne	a5,s2,8000377c <bread+0x3a>
      b->refcnt++;
    8000378e:	40bc                	lw	a5,64(s1)
    80003790:	2785                	addiw	a5,a5,1
    80003792:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003794:	00015517          	auipc	a0,0x15
    80003798:	4c450513          	addi	a0,a0,1220 # 80018c58 <bcache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	4fc080e7          	jalr	1276(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800037a4:	01048513          	addi	a0,s1,16
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	466080e7          	jalr	1126(ra) # 80004c0e <acquiresleep>
      return b;
    800037b0:	a8b9                	j	8000380e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037b2:	0001d497          	auipc	s1,0x1d
    800037b6:	7564b483          	ld	s1,1878(s1) # 80020f08 <bcache+0x82b0>
    800037ba:	0001d797          	auipc	a5,0x1d
    800037be:	70678793          	addi	a5,a5,1798 # 80020ec0 <bcache+0x8268>
    800037c2:	00f48863          	beq	s1,a5,800037d2 <bread+0x90>
    800037c6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800037c8:	40bc                	lw	a5,64(s1)
    800037ca:	cf81                	beqz	a5,800037e2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037cc:	64a4                	ld	s1,72(s1)
    800037ce:	fee49de3          	bne	s1,a4,800037c8 <bread+0x86>
  panic("bget: no buffers");
    800037d2:	00005517          	auipc	a0,0x5
    800037d6:	d6e50513          	addi	a0,a0,-658 # 80008540 <syscalls+0xd8>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	d64080e7          	jalr	-668(ra) # 8000053e <panic>
      b->dev = dev;
    800037e2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800037e6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800037ea:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037ee:	4785                	li	a5,1
    800037f0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037f2:	00015517          	auipc	a0,0x15
    800037f6:	46650513          	addi	a0,a0,1126 # 80018c58 <bcache>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	49e080e7          	jalr	1182(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003802:	01048513          	addi	a0,s1,16
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	408080e7          	jalr	1032(ra) # 80004c0e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000380e:	409c                	lw	a5,0(s1)
    80003810:	cb89                	beqz	a5,80003822 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003812:	8526                	mv	a0,s1
    80003814:	70a2                	ld	ra,40(sp)
    80003816:	7402                	ld	s0,32(sp)
    80003818:	64e2                	ld	s1,24(sp)
    8000381a:	6942                	ld	s2,16(sp)
    8000381c:	69a2                	ld	s3,8(sp)
    8000381e:	6145                	addi	sp,sp,48
    80003820:	8082                	ret
    virtio_disk_rw(b, 0);
    80003822:	4581                	li	a1,0
    80003824:	8526                	mv	a0,s1
    80003826:	00003097          	auipc	ra,0x3
    8000382a:	f10080e7          	jalr	-240(ra) # 80006736 <virtio_disk_rw>
    b->valid = 1;
    8000382e:	4785                	li	a5,1
    80003830:	c09c                	sw	a5,0(s1)
  return b;
    80003832:	b7c5                	j	80003812 <bread+0xd0>

0000000080003834 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003834:	1101                	addi	sp,sp,-32
    80003836:	ec06                	sd	ra,24(sp)
    80003838:	e822                	sd	s0,16(sp)
    8000383a:	e426                	sd	s1,8(sp)
    8000383c:	1000                	addi	s0,sp,32
    8000383e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003840:	0541                	addi	a0,a0,16
    80003842:	00001097          	auipc	ra,0x1
    80003846:	466080e7          	jalr	1126(ra) # 80004ca8 <holdingsleep>
    8000384a:	cd01                	beqz	a0,80003862 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000384c:	4585                	li	a1,1
    8000384e:	8526                	mv	a0,s1
    80003850:	00003097          	auipc	ra,0x3
    80003854:	ee6080e7          	jalr	-282(ra) # 80006736 <virtio_disk_rw>
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret
    panic("bwrite");
    80003862:	00005517          	auipc	a0,0x5
    80003866:	cf650513          	addi	a0,a0,-778 # 80008558 <syscalls+0xf0>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	cd4080e7          	jalr	-812(ra) # 8000053e <panic>

0000000080003872 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003872:	1101                	addi	sp,sp,-32
    80003874:	ec06                	sd	ra,24(sp)
    80003876:	e822                	sd	s0,16(sp)
    80003878:	e426                	sd	s1,8(sp)
    8000387a:	e04a                	sd	s2,0(sp)
    8000387c:	1000                	addi	s0,sp,32
    8000387e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003880:	01050913          	addi	s2,a0,16
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	422080e7          	jalr	1058(ra) # 80004ca8 <holdingsleep>
    8000388e:	c92d                	beqz	a0,80003900 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	3d2080e7          	jalr	978(ra) # 80004c64 <releasesleep>

  acquire(&bcache.lock);
    8000389a:	00015517          	auipc	a0,0x15
    8000389e:	3be50513          	addi	a0,a0,958 # 80018c58 <bcache>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
  b->refcnt--;
    800038aa:	40bc                	lw	a5,64(s1)
    800038ac:	37fd                	addiw	a5,a5,-1
    800038ae:	0007871b          	sext.w	a4,a5
    800038b2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800038b4:	eb05                	bnez	a4,800038e4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800038b6:	68bc                	ld	a5,80(s1)
    800038b8:	64b8                	ld	a4,72(s1)
    800038ba:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800038bc:	64bc                	ld	a5,72(s1)
    800038be:	68b8                	ld	a4,80(s1)
    800038c0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800038c2:	0001d797          	auipc	a5,0x1d
    800038c6:	39678793          	addi	a5,a5,918 # 80020c58 <bcache+0x8000>
    800038ca:	2b87b703          	ld	a4,696(a5)
    800038ce:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038d0:	0001d717          	auipc	a4,0x1d
    800038d4:	5f070713          	addi	a4,a4,1520 # 80020ec0 <bcache+0x8268>
    800038d8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038da:	2b87b703          	ld	a4,696(a5)
    800038de:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038e0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038e4:	00015517          	auipc	a0,0x15
    800038e8:	37450513          	addi	a0,a0,884 # 80018c58 <bcache>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
}
    800038f4:	60e2                	ld	ra,24(sp)
    800038f6:	6442                	ld	s0,16(sp)
    800038f8:	64a2                	ld	s1,8(sp)
    800038fa:	6902                	ld	s2,0(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret
    panic("brelse");
    80003900:	00005517          	auipc	a0,0x5
    80003904:	c6050513          	addi	a0,a0,-928 # 80008560 <syscalls+0xf8>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	c36080e7          	jalr	-970(ra) # 8000053e <panic>

0000000080003910 <bpin>:

void
bpin(struct buf *b) {
    80003910:	1101                	addi	sp,sp,-32
    80003912:	ec06                	sd	ra,24(sp)
    80003914:	e822                	sd	s0,16(sp)
    80003916:	e426                	sd	s1,8(sp)
    80003918:	1000                	addi	s0,sp,32
    8000391a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000391c:	00015517          	auipc	a0,0x15
    80003920:	33c50513          	addi	a0,a0,828 # 80018c58 <bcache>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	2c0080e7          	jalr	704(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000392c:	40bc                	lw	a5,64(s1)
    8000392e:	2785                	addiw	a5,a5,1
    80003930:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003932:	00015517          	auipc	a0,0x15
    80003936:	32650513          	addi	a0,a0,806 # 80018c58 <bcache>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	35e080e7          	jalr	862(ra) # 80000c98 <release>
}
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret

000000008000394c <bunpin>:

void
bunpin(struct buf *b) {
    8000394c:	1101                	addi	sp,sp,-32
    8000394e:	ec06                	sd	ra,24(sp)
    80003950:	e822                	sd	s0,16(sp)
    80003952:	e426                	sd	s1,8(sp)
    80003954:	1000                	addi	s0,sp,32
    80003956:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003958:	00015517          	auipc	a0,0x15
    8000395c:	30050513          	addi	a0,a0,768 # 80018c58 <bcache>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	284080e7          	jalr	644(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003968:	40bc                	lw	a5,64(s1)
    8000396a:	37fd                	addiw	a5,a5,-1
    8000396c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000396e:	00015517          	auipc	a0,0x15
    80003972:	2ea50513          	addi	a0,a0,746 # 80018c58 <bcache>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	322080e7          	jalr	802(ra) # 80000c98 <release>
}
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003996:	00d5d59b          	srliw	a1,a1,0xd
    8000399a:	0001e797          	auipc	a5,0x1e
    8000399e:	99a7a783          	lw	a5,-1638(a5) # 80021334 <sb+0x1c>
    800039a2:	9dbd                	addw	a1,a1,a5
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	d9e080e7          	jalr	-610(ra) # 80003742 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800039ac:	0074f713          	andi	a4,s1,7
    800039b0:	4785                	li	a5,1
    800039b2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800039b6:	14ce                	slli	s1,s1,0x33
    800039b8:	90d9                	srli	s1,s1,0x36
    800039ba:	00950733          	add	a4,a0,s1
    800039be:	05874703          	lbu	a4,88(a4)
    800039c2:	00e7f6b3          	and	a3,a5,a4
    800039c6:	c69d                	beqz	a3,800039f4 <bfree+0x6c>
    800039c8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800039ca:	94aa                	add	s1,s1,a0
    800039cc:	fff7c793          	not	a5,a5
    800039d0:	8ff9                	and	a5,a5,a4
    800039d2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	118080e7          	jalr	280(ra) # 80004aee <log_write>
  brelse(bp);
    800039de:	854a                	mv	a0,s2
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	e92080e7          	jalr	-366(ra) # 80003872 <brelse>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6902                	ld	s2,0(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret
    panic("freeing free block");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	b7450513          	addi	a0,a0,-1164 # 80008568 <syscalls+0x100>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>

0000000080003a04 <balloc>:
{
    80003a04:	711d                	addi	sp,sp,-96
    80003a06:	ec86                	sd	ra,88(sp)
    80003a08:	e8a2                	sd	s0,80(sp)
    80003a0a:	e4a6                	sd	s1,72(sp)
    80003a0c:	e0ca                	sd	s2,64(sp)
    80003a0e:	fc4e                	sd	s3,56(sp)
    80003a10:	f852                	sd	s4,48(sp)
    80003a12:	f456                	sd	s5,40(sp)
    80003a14:	f05a                	sd	s6,32(sp)
    80003a16:	ec5e                	sd	s7,24(sp)
    80003a18:	e862                	sd	s8,16(sp)
    80003a1a:	e466                	sd	s9,8(sp)
    80003a1c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a1e:	0001e797          	auipc	a5,0x1e
    80003a22:	8fe7a783          	lw	a5,-1794(a5) # 8002131c <sb+0x4>
    80003a26:	cbd1                	beqz	a5,80003aba <balloc+0xb6>
    80003a28:	8baa                	mv	s7,a0
    80003a2a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a2c:	0001eb17          	auipc	s6,0x1e
    80003a30:	8ecb0b13          	addi	s6,s6,-1812 # 80021318 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a34:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a36:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a38:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a3a:	6c89                	lui	s9,0x2
    80003a3c:	a831                	j	80003a58 <balloc+0x54>
    brelse(bp);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	e32080e7          	jalr	-462(ra) # 80003872 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a48:	015c87bb          	addw	a5,s9,s5
    80003a4c:	00078a9b          	sext.w	s5,a5
    80003a50:	004b2703          	lw	a4,4(s6)
    80003a54:	06eaf363          	bgeu	s5,a4,80003aba <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a58:	41fad79b          	sraiw	a5,s5,0x1f
    80003a5c:	0137d79b          	srliw	a5,a5,0x13
    80003a60:	015787bb          	addw	a5,a5,s5
    80003a64:	40d7d79b          	sraiw	a5,a5,0xd
    80003a68:	01cb2583          	lw	a1,28(s6)
    80003a6c:	9dbd                	addw	a1,a1,a5
    80003a6e:	855e                	mv	a0,s7
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	cd2080e7          	jalr	-814(ra) # 80003742 <bread>
    80003a78:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a7a:	004b2503          	lw	a0,4(s6)
    80003a7e:	000a849b          	sext.w	s1,s5
    80003a82:	8662                	mv	a2,s8
    80003a84:	faa4fde3          	bgeu	s1,a0,80003a3e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a88:	41f6579b          	sraiw	a5,a2,0x1f
    80003a8c:	01d7d69b          	srliw	a3,a5,0x1d
    80003a90:	00c6873b          	addw	a4,a3,a2
    80003a94:	00777793          	andi	a5,a4,7
    80003a98:	9f95                	subw	a5,a5,a3
    80003a9a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a9e:	4037571b          	sraiw	a4,a4,0x3
    80003aa2:	00e906b3          	add	a3,s2,a4
    80003aa6:	0586c683          	lbu	a3,88(a3)
    80003aaa:	00d7f5b3          	and	a1,a5,a3
    80003aae:	cd91                	beqz	a1,80003aca <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab0:	2605                	addiw	a2,a2,1
    80003ab2:	2485                	addiw	s1,s1,1
    80003ab4:	fd4618e3          	bne	a2,s4,80003a84 <balloc+0x80>
    80003ab8:	b759                	j	80003a3e <balloc+0x3a>
  panic("balloc: out of blocks");
    80003aba:	00005517          	auipc	a0,0x5
    80003abe:	ac650513          	addi	a0,a0,-1338 # 80008580 <syscalls+0x118>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003aca:	974a                	add	a4,a4,s2
    80003acc:	8fd5                	or	a5,a5,a3
    80003ace:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	01a080e7          	jalr	26(ra) # 80004aee <log_write>
        brelse(bp);
    80003adc:	854a                	mv	a0,s2
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	d94080e7          	jalr	-620(ra) # 80003872 <brelse>
  bp = bread(dev, bno);
    80003ae6:	85a6                	mv	a1,s1
    80003ae8:	855e                	mv	a0,s7
    80003aea:	00000097          	auipc	ra,0x0
    80003aee:	c58080e7          	jalr	-936(ra) # 80003742 <bread>
    80003af2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003af4:	40000613          	li	a2,1024
    80003af8:	4581                	li	a1,0
    80003afa:	05850513          	addi	a0,a0,88
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	1e2080e7          	jalr	482(ra) # 80000ce0 <memset>
  log_write(bp);
    80003b06:	854a                	mv	a0,s2
    80003b08:	00001097          	auipc	ra,0x1
    80003b0c:	fe6080e7          	jalr	-26(ra) # 80004aee <log_write>
  brelse(bp);
    80003b10:	854a                	mv	a0,s2
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	d60080e7          	jalr	-672(ra) # 80003872 <brelse>
}
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	60e6                	ld	ra,88(sp)
    80003b1e:	6446                	ld	s0,80(sp)
    80003b20:	64a6                	ld	s1,72(sp)
    80003b22:	6906                	ld	s2,64(sp)
    80003b24:	79e2                	ld	s3,56(sp)
    80003b26:	7a42                	ld	s4,48(sp)
    80003b28:	7aa2                	ld	s5,40(sp)
    80003b2a:	7b02                	ld	s6,32(sp)
    80003b2c:	6be2                	ld	s7,24(sp)
    80003b2e:	6c42                	ld	s8,16(sp)
    80003b30:	6ca2                	ld	s9,8(sp)
    80003b32:	6125                	addi	sp,sp,96
    80003b34:	8082                	ret

0000000080003b36 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b36:	7179                	addi	sp,sp,-48
    80003b38:	f406                	sd	ra,40(sp)
    80003b3a:	f022                	sd	s0,32(sp)
    80003b3c:	ec26                	sd	s1,24(sp)
    80003b3e:	e84a                	sd	s2,16(sp)
    80003b40:	e44e                	sd	s3,8(sp)
    80003b42:	e052                	sd	s4,0(sp)
    80003b44:	1800                	addi	s0,sp,48
    80003b46:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b48:	47ad                	li	a5,11
    80003b4a:	04b7fe63          	bgeu	a5,a1,80003ba6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b4e:	ff45849b          	addiw	s1,a1,-12
    80003b52:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b56:	0ff00793          	li	a5,255
    80003b5a:	0ae7e363          	bltu	a5,a4,80003c00 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b5e:	08052583          	lw	a1,128(a0)
    80003b62:	c5ad                	beqz	a1,80003bcc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b64:	00092503          	lw	a0,0(s2)
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	bda080e7          	jalr	-1062(ra) # 80003742 <bread>
    80003b70:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b72:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b76:	02049593          	slli	a1,s1,0x20
    80003b7a:	9181                	srli	a1,a1,0x20
    80003b7c:	058a                	slli	a1,a1,0x2
    80003b7e:	00b784b3          	add	s1,a5,a1
    80003b82:	0004a983          	lw	s3,0(s1)
    80003b86:	04098d63          	beqz	s3,80003be0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b8a:	8552                	mv	a0,s4
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	ce6080e7          	jalr	-794(ra) # 80003872 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b94:	854e                	mv	a0,s3
    80003b96:	70a2                	ld	ra,40(sp)
    80003b98:	7402                	ld	s0,32(sp)
    80003b9a:	64e2                	ld	s1,24(sp)
    80003b9c:	6942                	ld	s2,16(sp)
    80003b9e:	69a2                	ld	s3,8(sp)
    80003ba0:	6a02                	ld	s4,0(sp)
    80003ba2:	6145                	addi	sp,sp,48
    80003ba4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003ba6:	02059493          	slli	s1,a1,0x20
    80003baa:	9081                	srli	s1,s1,0x20
    80003bac:	048a                	slli	s1,s1,0x2
    80003bae:	94aa                	add	s1,s1,a0
    80003bb0:	0504a983          	lw	s3,80(s1)
    80003bb4:	fe0990e3          	bnez	s3,80003b94 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003bb8:	4108                	lw	a0,0(a0)
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	e4a080e7          	jalr	-438(ra) # 80003a04 <balloc>
    80003bc2:	0005099b          	sext.w	s3,a0
    80003bc6:	0534a823          	sw	s3,80(s1)
    80003bca:	b7e9                	j	80003b94 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003bcc:	4108                	lw	a0,0(a0)
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	e36080e7          	jalr	-458(ra) # 80003a04 <balloc>
    80003bd6:	0005059b          	sext.w	a1,a0
    80003bda:	08b92023          	sw	a1,128(s2)
    80003bde:	b759                	j	80003b64 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003be0:	00092503          	lw	a0,0(s2)
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	e20080e7          	jalr	-480(ra) # 80003a04 <balloc>
    80003bec:	0005099b          	sext.w	s3,a0
    80003bf0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bf4:	8552                	mv	a0,s4
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	ef8080e7          	jalr	-264(ra) # 80004aee <log_write>
    80003bfe:	b771                	j	80003b8a <bmap+0x54>
  panic("bmap: out of range");
    80003c00:	00005517          	auipc	a0,0x5
    80003c04:	99850513          	addi	a0,a0,-1640 # 80008598 <syscalls+0x130>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>

0000000080003c10 <iget>:
{
    80003c10:	7179                	addi	sp,sp,-48
    80003c12:	f406                	sd	ra,40(sp)
    80003c14:	f022                	sd	s0,32(sp)
    80003c16:	ec26                	sd	s1,24(sp)
    80003c18:	e84a                	sd	s2,16(sp)
    80003c1a:	e44e                	sd	s3,8(sp)
    80003c1c:	e052                	sd	s4,0(sp)
    80003c1e:	1800                	addi	s0,sp,48
    80003c20:	89aa                	mv	s3,a0
    80003c22:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c24:	0001d517          	auipc	a0,0x1d
    80003c28:	71450513          	addi	a0,a0,1812 # 80021338 <itable>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	fb8080e7          	jalr	-72(ra) # 80000be4 <acquire>
  empty = 0;
    80003c34:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c36:	0001d497          	auipc	s1,0x1d
    80003c3a:	71a48493          	addi	s1,s1,1818 # 80021350 <itable+0x18>
    80003c3e:	0001f697          	auipc	a3,0x1f
    80003c42:	1a268693          	addi	a3,a3,418 # 80022de0 <log>
    80003c46:	a039                	j	80003c54 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c48:	02090b63          	beqz	s2,80003c7e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c4c:	08848493          	addi	s1,s1,136
    80003c50:	02d48a63          	beq	s1,a3,80003c84 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c54:	449c                	lw	a5,8(s1)
    80003c56:	fef059e3          	blez	a5,80003c48 <iget+0x38>
    80003c5a:	4098                	lw	a4,0(s1)
    80003c5c:	ff3716e3          	bne	a4,s3,80003c48 <iget+0x38>
    80003c60:	40d8                	lw	a4,4(s1)
    80003c62:	ff4713e3          	bne	a4,s4,80003c48 <iget+0x38>
      ip->ref++;
    80003c66:	2785                	addiw	a5,a5,1
    80003c68:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c6a:	0001d517          	auipc	a0,0x1d
    80003c6e:	6ce50513          	addi	a0,a0,1742 # 80021338 <itable>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	026080e7          	jalr	38(ra) # 80000c98 <release>
      return ip;
    80003c7a:	8926                	mv	s2,s1
    80003c7c:	a03d                	j	80003caa <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c7e:	f7f9                	bnez	a5,80003c4c <iget+0x3c>
    80003c80:	8926                	mv	s2,s1
    80003c82:	b7e9                	j	80003c4c <iget+0x3c>
  if(empty == 0)
    80003c84:	02090c63          	beqz	s2,80003cbc <iget+0xac>
  ip->dev = dev;
    80003c88:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c8c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c90:	4785                	li	a5,1
    80003c92:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c96:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c9a:	0001d517          	auipc	a0,0x1d
    80003c9e:	69e50513          	addi	a0,a0,1694 # 80021338 <itable>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	ff6080e7          	jalr	-10(ra) # 80000c98 <release>
}
    80003caa:	854a                	mv	a0,s2
    80003cac:	70a2                	ld	ra,40(sp)
    80003cae:	7402                	ld	s0,32(sp)
    80003cb0:	64e2                	ld	s1,24(sp)
    80003cb2:	6942                	ld	s2,16(sp)
    80003cb4:	69a2                	ld	s3,8(sp)
    80003cb6:	6a02                	ld	s4,0(sp)
    80003cb8:	6145                	addi	sp,sp,48
    80003cba:	8082                	ret
    panic("iget: no inodes");
    80003cbc:	00005517          	auipc	a0,0x5
    80003cc0:	8f450513          	addi	a0,a0,-1804 # 800085b0 <syscalls+0x148>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	87a080e7          	jalr	-1926(ra) # 8000053e <panic>

0000000080003ccc <fsinit>:
fsinit(int dev) {
    80003ccc:	7179                	addi	sp,sp,-48
    80003cce:	f406                	sd	ra,40(sp)
    80003cd0:	f022                	sd	s0,32(sp)
    80003cd2:	ec26                	sd	s1,24(sp)
    80003cd4:	e84a                	sd	s2,16(sp)
    80003cd6:	e44e                	sd	s3,8(sp)
    80003cd8:	1800                	addi	s0,sp,48
    80003cda:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cdc:	4585                	li	a1,1
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	a64080e7          	jalr	-1436(ra) # 80003742 <bread>
    80003ce6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ce8:	0001d997          	auipc	s3,0x1d
    80003cec:	63098993          	addi	s3,s3,1584 # 80021318 <sb>
    80003cf0:	02000613          	li	a2,32
    80003cf4:	05850593          	addi	a1,a0,88
    80003cf8:	854e                	mv	a0,s3
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	046080e7          	jalr	70(ra) # 80000d40 <memmove>
  brelse(bp);
    80003d02:	8526                	mv	a0,s1
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	b6e080e7          	jalr	-1170(ra) # 80003872 <brelse>
  if(sb.magic != FSMAGIC)
    80003d0c:	0009a703          	lw	a4,0(s3)
    80003d10:	102037b7          	lui	a5,0x10203
    80003d14:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d18:	02f71263          	bne	a4,a5,80003d3c <fsinit+0x70>
  initlog(dev, &sb);
    80003d1c:	0001d597          	auipc	a1,0x1d
    80003d20:	5fc58593          	addi	a1,a1,1532 # 80021318 <sb>
    80003d24:	854a                	mv	a0,s2
    80003d26:	00001097          	auipc	ra,0x1
    80003d2a:	b4c080e7          	jalr	-1204(ra) # 80004872 <initlog>
}
    80003d2e:	70a2                	ld	ra,40(sp)
    80003d30:	7402                	ld	s0,32(sp)
    80003d32:	64e2                	ld	s1,24(sp)
    80003d34:	6942                	ld	s2,16(sp)
    80003d36:	69a2                	ld	s3,8(sp)
    80003d38:	6145                	addi	sp,sp,48
    80003d3a:	8082                	ret
    panic("invalid file system");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	88450513          	addi	a0,a0,-1916 # 800085c0 <syscalls+0x158>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>

0000000080003d4c <iinit>:
{
    80003d4c:	7179                	addi	sp,sp,-48
    80003d4e:	f406                	sd	ra,40(sp)
    80003d50:	f022                	sd	s0,32(sp)
    80003d52:	ec26                	sd	s1,24(sp)
    80003d54:	e84a                	sd	s2,16(sp)
    80003d56:	e44e                	sd	s3,8(sp)
    80003d58:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d5a:	00005597          	auipc	a1,0x5
    80003d5e:	87e58593          	addi	a1,a1,-1922 # 800085d8 <syscalls+0x170>
    80003d62:	0001d517          	auipc	a0,0x1d
    80003d66:	5d650513          	addi	a0,a0,1494 # 80021338 <itable>
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	dea080e7          	jalr	-534(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d72:	0001d497          	auipc	s1,0x1d
    80003d76:	5ee48493          	addi	s1,s1,1518 # 80021360 <itable+0x28>
    80003d7a:	0001f997          	auipc	s3,0x1f
    80003d7e:	07698993          	addi	s3,s3,118 # 80022df0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d82:	00005917          	auipc	s2,0x5
    80003d86:	85e90913          	addi	s2,s2,-1954 # 800085e0 <syscalls+0x178>
    80003d8a:	85ca                	mv	a1,s2
    80003d8c:	8526                	mv	a0,s1
    80003d8e:	00001097          	auipc	ra,0x1
    80003d92:	e46080e7          	jalr	-442(ra) # 80004bd4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d96:	08848493          	addi	s1,s1,136
    80003d9a:	ff3498e3          	bne	s1,s3,80003d8a <iinit+0x3e>
}
    80003d9e:	70a2                	ld	ra,40(sp)
    80003da0:	7402                	ld	s0,32(sp)
    80003da2:	64e2                	ld	s1,24(sp)
    80003da4:	6942                	ld	s2,16(sp)
    80003da6:	69a2                	ld	s3,8(sp)
    80003da8:	6145                	addi	sp,sp,48
    80003daa:	8082                	ret

0000000080003dac <ialloc>:
{
    80003dac:	715d                	addi	sp,sp,-80
    80003dae:	e486                	sd	ra,72(sp)
    80003db0:	e0a2                	sd	s0,64(sp)
    80003db2:	fc26                	sd	s1,56(sp)
    80003db4:	f84a                	sd	s2,48(sp)
    80003db6:	f44e                	sd	s3,40(sp)
    80003db8:	f052                	sd	s4,32(sp)
    80003dba:	ec56                	sd	s5,24(sp)
    80003dbc:	e85a                	sd	s6,16(sp)
    80003dbe:	e45e                	sd	s7,8(sp)
    80003dc0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dc2:	0001d717          	auipc	a4,0x1d
    80003dc6:	56272703          	lw	a4,1378(a4) # 80021324 <sb+0xc>
    80003dca:	4785                	li	a5,1
    80003dcc:	04e7fa63          	bgeu	a5,a4,80003e20 <ialloc+0x74>
    80003dd0:	8aaa                	mv	s5,a0
    80003dd2:	8bae                	mv	s7,a1
    80003dd4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003dd6:	0001da17          	auipc	s4,0x1d
    80003dda:	542a0a13          	addi	s4,s4,1346 # 80021318 <sb>
    80003dde:	00048b1b          	sext.w	s6,s1
    80003de2:	0044d593          	srli	a1,s1,0x4
    80003de6:	018a2783          	lw	a5,24(s4)
    80003dea:	9dbd                	addw	a1,a1,a5
    80003dec:	8556                	mv	a0,s5
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	954080e7          	jalr	-1708(ra) # 80003742 <bread>
    80003df6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003df8:	05850993          	addi	s3,a0,88
    80003dfc:	00f4f793          	andi	a5,s1,15
    80003e00:	079a                	slli	a5,a5,0x6
    80003e02:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e04:	00099783          	lh	a5,0(s3)
    80003e08:	c785                	beqz	a5,80003e30 <ialloc+0x84>
    brelse(bp);
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	a68080e7          	jalr	-1432(ra) # 80003872 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e12:	0485                	addi	s1,s1,1
    80003e14:	00ca2703          	lw	a4,12(s4)
    80003e18:	0004879b          	sext.w	a5,s1
    80003e1c:	fce7e1e3          	bltu	a5,a4,80003dde <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e20:	00004517          	auipc	a0,0x4
    80003e24:	7c850513          	addi	a0,a0,1992 # 800085e8 <syscalls+0x180>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	716080e7          	jalr	1814(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003e30:	04000613          	li	a2,64
    80003e34:	4581                	li	a1,0
    80003e36:	854e                	mv	a0,s3
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	ea8080e7          	jalr	-344(ra) # 80000ce0 <memset>
      dip->type = type;
    80003e40:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e44:	854a                	mv	a0,s2
    80003e46:	00001097          	auipc	ra,0x1
    80003e4a:	ca8080e7          	jalr	-856(ra) # 80004aee <log_write>
      brelse(bp);
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	a22080e7          	jalr	-1502(ra) # 80003872 <brelse>
      return iget(dev, inum);
    80003e58:	85da                	mv	a1,s6
    80003e5a:	8556                	mv	a0,s5
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	db4080e7          	jalr	-588(ra) # 80003c10 <iget>
}
    80003e64:	60a6                	ld	ra,72(sp)
    80003e66:	6406                	ld	s0,64(sp)
    80003e68:	74e2                	ld	s1,56(sp)
    80003e6a:	7942                	ld	s2,48(sp)
    80003e6c:	79a2                	ld	s3,40(sp)
    80003e6e:	7a02                	ld	s4,32(sp)
    80003e70:	6ae2                	ld	s5,24(sp)
    80003e72:	6b42                	ld	s6,16(sp)
    80003e74:	6ba2                	ld	s7,8(sp)
    80003e76:	6161                	addi	sp,sp,80
    80003e78:	8082                	ret

0000000080003e7a <iupdate>:
{
    80003e7a:	1101                	addi	sp,sp,-32
    80003e7c:	ec06                	sd	ra,24(sp)
    80003e7e:	e822                	sd	s0,16(sp)
    80003e80:	e426                	sd	s1,8(sp)
    80003e82:	e04a                	sd	s2,0(sp)
    80003e84:	1000                	addi	s0,sp,32
    80003e86:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e88:	415c                	lw	a5,4(a0)
    80003e8a:	0047d79b          	srliw	a5,a5,0x4
    80003e8e:	0001d597          	auipc	a1,0x1d
    80003e92:	4a25a583          	lw	a1,1186(a1) # 80021330 <sb+0x18>
    80003e96:	9dbd                	addw	a1,a1,a5
    80003e98:	4108                	lw	a0,0(a0)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	8a8080e7          	jalr	-1880(ra) # 80003742 <bread>
    80003ea2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ea4:	05850793          	addi	a5,a0,88
    80003ea8:	40c8                	lw	a0,4(s1)
    80003eaa:	893d                	andi	a0,a0,15
    80003eac:	051a                	slli	a0,a0,0x6
    80003eae:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003eb0:	04449703          	lh	a4,68(s1)
    80003eb4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003eb8:	04649703          	lh	a4,70(s1)
    80003ebc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ec0:	04849703          	lh	a4,72(s1)
    80003ec4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ec8:	04a49703          	lh	a4,74(s1)
    80003ecc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ed0:	44f8                	lw	a4,76(s1)
    80003ed2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ed4:	03400613          	li	a2,52
    80003ed8:	05048593          	addi	a1,s1,80
    80003edc:	0531                	addi	a0,a0,12
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	e62080e7          	jalr	-414(ra) # 80000d40 <memmove>
  log_write(bp);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	00001097          	auipc	ra,0x1
    80003eec:	c06080e7          	jalr	-1018(ra) # 80004aee <log_write>
  brelse(bp);
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	980080e7          	jalr	-1664(ra) # 80003872 <brelse>
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6902                	ld	s2,0(sp)
    80003f02:	6105                	addi	sp,sp,32
    80003f04:	8082                	ret

0000000080003f06 <idup>:
{
    80003f06:	1101                	addi	sp,sp,-32
    80003f08:	ec06                	sd	ra,24(sp)
    80003f0a:	e822                	sd	s0,16(sp)
    80003f0c:	e426                	sd	s1,8(sp)
    80003f0e:	1000                	addi	s0,sp,32
    80003f10:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f12:	0001d517          	auipc	a0,0x1d
    80003f16:	42650513          	addi	a0,a0,1062 # 80021338 <itable>
    80003f1a:	ffffd097          	auipc	ra,0xffffd
    80003f1e:	cca080e7          	jalr	-822(ra) # 80000be4 <acquire>
  ip->ref++;
    80003f22:	449c                	lw	a5,8(s1)
    80003f24:	2785                	addiw	a5,a5,1
    80003f26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f28:	0001d517          	auipc	a0,0x1d
    80003f2c:	41050513          	addi	a0,a0,1040 # 80021338 <itable>
    80003f30:	ffffd097          	auipc	ra,0xffffd
    80003f34:	d68080e7          	jalr	-664(ra) # 80000c98 <release>
}
    80003f38:	8526                	mv	a0,s1
    80003f3a:	60e2                	ld	ra,24(sp)
    80003f3c:	6442                	ld	s0,16(sp)
    80003f3e:	64a2                	ld	s1,8(sp)
    80003f40:	6105                	addi	sp,sp,32
    80003f42:	8082                	ret

0000000080003f44 <ilock>:
{
    80003f44:	1101                	addi	sp,sp,-32
    80003f46:	ec06                	sd	ra,24(sp)
    80003f48:	e822                	sd	s0,16(sp)
    80003f4a:	e426                	sd	s1,8(sp)
    80003f4c:	e04a                	sd	s2,0(sp)
    80003f4e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f50:	c115                	beqz	a0,80003f74 <ilock+0x30>
    80003f52:	84aa                	mv	s1,a0
    80003f54:	451c                	lw	a5,8(a0)
    80003f56:	00f05f63          	blez	a5,80003f74 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f5a:	0541                	addi	a0,a0,16
    80003f5c:	00001097          	auipc	ra,0x1
    80003f60:	cb2080e7          	jalr	-846(ra) # 80004c0e <acquiresleep>
  if(ip->valid == 0){
    80003f64:	40bc                	lw	a5,64(s1)
    80003f66:	cf99                	beqz	a5,80003f84 <ilock+0x40>
}
    80003f68:	60e2                	ld	ra,24(sp)
    80003f6a:	6442                	ld	s0,16(sp)
    80003f6c:	64a2                	ld	s1,8(sp)
    80003f6e:	6902                	ld	s2,0(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret
    panic("ilock");
    80003f74:	00004517          	auipc	a0,0x4
    80003f78:	68c50513          	addi	a0,a0,1676 # 80008600 <syscalls+0x198>
    80003f7c:	ffffc097          	auipc	ra,0xffffc
    80003f80:	5c2080e7          	jalr	1474(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f84:	40dc                	lw	a5,4(s1)
    80003f86:	0047d79b          	srliw	a5,a5,0x4
    80003f8a:	0001d597          	auipc	a1,0x1d
    80003f8e:	3a65a583          	lw	a1,934(a1) # 80021330 <sb+0x18>
    80003f92:	9dbd                	addw	a1,a1,a5
    80003f94:	4088                	lw	a0,0(s1)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	7ac080e7          	jalr	1964(ra) # 80003742 <bread>
    80003f9e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fa0:	05850593          	addi	a1,a0,88
    80003fa4:	40dc                	lw	a5,4(s1)
    80003fa6:	8bbd                	andi	a5,a5,15
    80003fa8:	079a                	slli	a5,a5,0x6
    80003faa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003fac:	00059783          	lh	a5,0(a1)
    80003fb0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003fb4:	00259783          	lh	a5,2(a1)
    80003fb8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003fbc:	00459783          	lh	a5,4(a1)
    80003fc0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fc4:	00659783          	lh	a5,6(a1)
    80003fc8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fcc:	459c                	lw	a5,8(a1)
    80003fce:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fd0:	03400613          	li	a2,52
    80003fd4:	05b1                	addi	a1,a1,12
    80003fd6:	05048513          	addi	a0,s1,80
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	d66080e7          	jalr	-666(ra) # 80000d40 <memmove>
    brelse(bp);
    80003fe2:	854a                	mv	a0,s2
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	88e080e7          	jalr	-1906(ra) # 80003872 <brelse>
    ip->valid = 1;
    80003fec:	4785                	li	a5,1
    80003fee:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ff0:	04449783          	lh	a5,68(s1)
    80003ff4:	fbb5                	bnez	a5,80003f68 <ilock+0x24>
      panic("ilock: no type");
    80003ff6:	00004517          	auipc	a0,0x4
    80003ffa:	61250513          	addi	a0,a0,1554 # 80008608 <syscalls+0x1a0>
    80003ffe:	ffffc097          	auipc	ra,0xffffc
    80004002:	540080e7          	jalr	1344(ra) # 8000053e <panic>

0000000080004006 <iunlock>:
{
    80004006:	1101                	addi	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	e426                	sd	s1,8(sp)
    8000400e:	e04a                	sd	s2,0(sp)
    80004010:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004012:	c905                	beqz	a0,80004042 <iunlock+0x3c>
    80004014:	84aa                	mv	s1,a0
    80004016:	01050913          	addi	s2,a0,16
    8000401a:	854a                	mv	a0,s2
    8000401c:	00001097          	auipc	ra,0x1
    80004020:	c8c080e7          	jalr	-884(ra) # 80004ca8 <holdingsleep>
    80004024:	cd19                	beqz	a0,80004042 <iunlock+0x3c>
    80004026:	449c                	lw	a5,8(s1)
    80004028:	00f05d63          	blez	a5,80004042 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000402c:	854a                	mv	a0,s2
    8000402e:	00001097          	auipc	ra,0x1
    80004032:	c36080e7          	jalr	-970(ra) # 80004c64 <releasesleep>
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6902                	ld	s2,0(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret
    panic("iunlock");
    80004042:	00004517          	auipc	a0,0x4
    80004046:	5d650513          	addi	a0,a0,1494 # 80008618 <syscalls+0x1b0>
    8000404a:	ffffc097          	auipc	ra,0xffffc
    8000404e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>

0000000080004052 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004052:	7179                	addi	sp,sp,-48
    80004054:	f406                	sd	ra,40(sp)
    80004056:	f022                	sd	s0,32(sp)
    80004058:	ec26                	sd	s1,24(sp)
    8000405a:	e84a                	sd	s2,16(sp)
    8000405c:	e44e                	sd	s3,8(sp)
    8000405e:	e052                	sd	s4,0(sp)
    80004060:	1800                	addi	s0,sp,48
    80004062:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004064:	05050493          	addi	s1,a0,80
    80004068:	08050913          	addi	s2,a0,128
    8000406c:	a021                	j	80004074 <itrunc+0x22>
    8000406e:	0491                	addi	s1,s1,4
    80004070:	01248d63          	beq	s1,s2,8000408a <itrunc+0x38>
    if(ip->addrs[i]){
    80004074:	408c                	lw	a1,0(s1)
    80004076:	dde5                	beqz	a1,8000406e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004078:	0009a503          	lw	a0,0(s3)
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	90c080e7          	jalr	-1780(ra) # 80003988 <bfree>
      ip->addrs[i] = 0;
    80004084:	0004a023          	sw	zero,0(s1)
    80004088:	b7dd                	j	8000406e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000408a:	0809a583          	lw	a1,128(s3)
    8000408e:	e185                	bnez	a1,800040ae <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004090:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004094:	854e                	mv	a0,s3
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	de4080e7          	jalr	-540(ra) # 80003e7a <iupdate>
}
    8000409e:	70a2                	ld	ra,40(sp)
    800040a0:	7402                	ld	s0,32(sp)
    800040a2:	64e2                	ld	s1,24(sp)
    800040a4:	6942                	ld	s2,16(sp)
    800040a6:	69a2                	ld	s3,8(sp)
    800040a8:	6a02                	ld	s4,0(sp)
    800040aa:	6145                	addi	sp,sp,48
    800040ac:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800040ae:	0009a503          	lw	a0,0(s3)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	690080e7          	jalr	1680(ra) # 80003742 <bread>
    800040ba:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800040bc:	05850493          	addi	s1,a0,88
    800040c0:	45850913          	addi	s2,a0,1112
    800040c4:	a811                	j	800040d8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800040c6:	0009a503          	lw	a0,0(s3)
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	8be080e7          	jalr	-1858(ra) # 80003988 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800040d2:	0491                	addi	s1,s1,4
    800040d4:	01248563          	beq	s1,s2,800040de <itrunc+0x8c>
      if(a[j])
    800040d8:	408c                	lw	a1,0(s1)
    800040da:	dde5                	beqz	a1,800040d2 <itrunc+0x80>
    800040dc:	b7ed                	j	800040c6 <itrunc+0x74>
    brelse(bp);
    800040de:	8552                	mv	a0,s4
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	792080e7          	jalr	1938(ra) # 80003872 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040e8:	0809a583          	lw	a1,128(s3)
    800040ec:	0009a503          	lw	a0,0(s3)
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	898080e7          	jalr	-1896(ra) # 80003988 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040f8:	0809a023          	sw	zero,128(s3)
    800040fc:	bf51                	j	80004090 <itrunc+0x3e>

00000000800040fe <iput>:
{
    800040fe:	1101                	addi	sp,sp,-32
    80004100:	ec06                	sd	ra,24(sp)
    80004102:	e822                	sd	s0,16(sp)
    80004104:	e426                	sd	s1,8(sp)
    80004106:	e04a                	sd	s2,0(sp)
    80004108:	1000                	addi	s0,sp,32
    8000410a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000410c:	0001d517          	auipc	a0,0x1d
    80004110:	22c50513          	addi	a0,a0,556 # 80021338 <itable>
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000411c:	4498                	lw	a4,8(s1)
    8000411e:	4785                	li	a5,1
    80004120:	02f70363          	beq	a4,a5,80004146 <iput+0x48>
  ip->ref--;
    80004124:	449c                	lw	a5,8(s1)
    80004126:	37fd                	addiw	a5,a5,-1
    80004128:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000412a:	0001d517          	auipc	a0,0x1d
    8000412e:	20e50513          	addi	a0,a0,526 # 80021338 <itable>
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
}
    8000413a:	60e2                	ld	ra,24(sp)
    8000413c:	6442                	ld	s0,16(sp)
    8000413e:	64a2                	ld	s1,8(sp)
    80004140:	6902                	ld	s2,0(sp)
    80004142:	6105                	addi	sp,sp,32
    80004144:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004146:	40bc                	lw	a5,64(s1)
    80004148:	dff1                	beqz	a5,80004124 <iput+0x26>
    8000414a:	04a49783          	lh	a5,74(s1)
    8000414e:	fbf9                	bnez	a5,80004124 <iput+0x26>
    acquiresleep(&ip->lock);
    80004150:	01048913          	addi	s2,s1,16
    80004154:	854a                	mv	a0,s2
    80004156:	00001097          	auipc	ra,0x1
    8000415a:	ab8080e7          	jalr	-1352(ra) # 80004c0e <acquiresleep>
    release(&itable.lock);
    8000415e:	0001d517          	auipc	a0,0x1d
    80004162:	1da50513          	addi	a0,a0,474 # 80021338 <itable>
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
    itrunc(ip);
    8000416e:	8526                	mv	a0,s1
    80004170:	00000097          	auipc	ra,0x0
    80004174:	ee2080e7          	jalr	-286(ra) # 80004052 <itrunc>
    ip->type = 0;
    80004178:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000417c:	8526                	mv	a0,s1
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	cfc080e7          	jalr	-772(ra) # 80003e7a <iupdate>
    ip->valid = 0;
    80004186:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000418a:	854a                	mv	a0,s2
    8000418c:	00001097          	auipc	ra,0x1
    80004190:	ad8080e7          	jalr	-1320(ra) # 80004c64 <releasesleep>
    acquire(&itable.lock);
    80004194:	0001d517          	auipc	a0,0x1d
    80004198:	1a450513          	addi	a0,a0,420 # 80021338 <itable>
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
    800041a4:	b741                	j	80004124 <iput+0x26>

00000000800041a6 <iunlockput>:
{
    800041a6:	1101                	addi	sp,sp,-32
    800041a8:	ec06                	sd	ra,24(sp)
    800041aa:	e822                	sd	s0,16(sp)
    800041ac:	e426                	sd	s1,8(sp)
    800041ae:	1000                	addi	s0,sp,32
    800041b0:	84aa                	mv	s1,a0
  iunlock(ip);
    800041b2:	00000097          	auipc	ra,0x0
    800041b6:	e54080e7          	jalr	-428(ra) # 80004006 <iunlock>
  iput(ip);
    800041ba:	8526                	mv	a0,s1
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	f42080e7          	jalr	-190(ra) # 800040fe <iput>
}
    800041c4:	60e2                	ld	ra,24(sp)
    800041c6:	6442                	ld	s0,16(sp)
    800041c8:	64a2                	ld	s1,8(sp)
    800041ca:	6105                	addi	sp,sp,32
    800041cc:	8082                	ret

00000000800041ce <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041ce:	1141                	addi	sp,sp,-16
    800041d0:	e422                	sd	s0,8(sp)
    800041d2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041d4:	411c                	lw	a5,0(a0)
    800041d6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041d8:	415c                	lw	a5,4(a0)
    800041da:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041dc:	04451783          	lh	a5,68(a0)
    800041e0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041e4:	04a51783          	lh	a5,74(a0)
    800041e8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041ec:	04c56783          	lwu	a5,76(a0)
    800041f0:	e99c                	sd	a5,16(a1)
}
    800041f2:	6422                	ld	s0,8(sp)
    800041f4:	0141                	addi	sp,sp,16
    800041f6:	8082                	ret

00000000800041f8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041f8:	457c                	lw	a5,76(a0)
    800041fa:	0ed7e963          	bltu	a5,a3,800042ec <readi+0xf4>
{
    800041fe:	7159                	addi	sp,sp,-112
    80004200:	f486                	sd	ra,104(sp)
    80004202:	f0a2                	sd	s0,96(sp)
    80004204:	eca6                	sd	s1,88(sp)
    80004206:	e8ca                	sd	s2,80(sp)
    80004208:	e4ce                	sd	s3,72(sp)
    8000420a:	e0d2                	sd	s4,64(sp)
    8000420c:	fc56                	sd	s5,56(sp)
    8000420e:	f85a                	sd	s6,48(sp)
    80004210:	f45e                	sd	s7,40(sp)
    80004212:	f062                	sd	s8,32(sp)
    80004214:	ec66                	sd	s9,24(sp)
    80004216:	e86a                	sd	s10,16(sp)
    80004218:	e46e                	sd	s11,8(sp)
    8000421a:	1880                	addi	s0,sp,112
    8000421c:	8baa                	mv	s7,a0
    8000421e:	8c2e                	mv	s8,a1
    80004220:	8ab2                	mv	s5,a2
    80004222:	84b6                	mv	s1,a3
    80004224:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004226:	9f35                	addw	a4,a4,a3
    return 0;
    80004228:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000422a:	0ad76063          	bltu	a4,a3,800042ca <readi+0xd2>
  if(off + n > ip->size)
    8000422e:	00e7f463          	bgeu	a5,a4,80004236 <readi+0x3e>
    n = ip->size - off;
    80004232:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004236:	0a0b0963          	beqz	s6,800042e8 <readi+0xf0>
    8000423a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004240:	5cfd                	li	s9,-1
    80004242:	a82d                	j	8000427c <readi+0x84>
    80004244:	020a1d93          	slli	s11,s4,0x20
    80004248:	020ddd93          	srli	s11,s11,0x20
    8000424c:	05890613          	addi	a2,s2,88
    80004250:	86ee                	mv	a3,s11
    80004252:	963a                	add	a2,a2,a4
    80004254:	85d6                	mv	a1,s5
    80004256:	8562                	mv	a0,s8
    80004258:	ffffe097          	auipc	ra,0xffffe
    8000425c:	9ae080e7          	jalr	-1618(ra) # 80001c06 <either_copyout>
    80004260:	05950d63          	beq	a0,s9,800042ba <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004264:	854a                	mv	a0,s2
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	60c080e7          	jalr	1548(ra) # 80003872 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000426e:	013a09bb          	addw	s3,s4,s3
    80004272:	009a04bb          	addw	s1,s4,s1
    80004276:	9aee                	add	s5,s5,s11
    80004278:	0569f763          	bgeu	s3,s6,800042c6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000427c:	000ba903          	lw	s2,0(s7)
    80004280:	00a4d59b          	srliw	a1,s1,0xa
    80004284:	855e                	mv	a0,s7
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	8b0080e7          	jalr	-1872(ra) # 80003b36 <bmap>
    8000428e:	0005059b          	sext.w	a1,a0
    80004292:	854a                	mv	a0,s2
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	4ae080e7          	jalr	1198(ra) # 80003742 <bread>
    8000429c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000429e:	3ff4f713          	andi	a4,s1,1023
    800042a2:	40ed07bb          	subw	a5,s10,a4
    800042a6:	413b06bb          	subw	a3,s6,s3
    800042aa:	8a3e                	mv	s4,a5
    800042ac:	2781                	sext.w	a5,a5
    800042ae:	0006861b          	sext.w	a2,a3
    800042b2:	f8f679e3          	bgeu	a2,a5,80004244 <readi+0x4c>
    800042b6:	8a36                	mv	s4,a3
    800042b8:	b771                	j	80004244 <readi+0x4c>
      brelse(bp);
    800042ba:	854a                	mv	a0,s2
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	5b6080e7          	jalr	1462(ra) # 80003872 <brelse>
      tot = -1;
    800042c4:	59fd                	li	s3,-1
  }
  return tot;
    800042c6:	0009851b          	sext.w	a0,s3
}
    800042ca:	70a6                	ld	ra,104(sp)
    800042cc:	7406                	ld	s0,96(sp)
    800042ce:	64e6                	ld	s1,88(sp)
    800042d0:	6946                	ld	s2,80(sp)
    800042d2:	69a6                	ld	s3,72(sp)
    800042d4:	6a06                	ld	s4,64(sp)
    800042d6:	7ae2                	ld	s5,56(sp)
    800042d8:	7b42                	ld	s6,48(sp)
    800042da:	7ba2                	ld	s7,40(sp)
    800042dc:	7c02                	ld	s8,32(sp)
    800042de:	6ce2                	ld	s9,24(sp)
    800042e0:	6d42                	ld	s10,16(sp)
    800042e2:	6da2                	ld	s11,8(sp)
    800042e4:	6165                	addi	sp,sp,112
    800042e6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042e8:	89da                	mv	s3,s6
    800042ea:	bff1                	j	800042c6 <readi+0xce>
    return 0;
    800042ec:	4501                	li	a0,0
}
    800042ee:	8082                	ret

00000000800042f0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042f0:	457c                	lw	a5,76(a0)
    800042f2:	10d7e863          	bltu	a5,a3,80004402 <writei+0x112>
{
    800042f6:	7159                	addi	sp,sp,-112
    800042f8:	f486                	sd	ra,104(sp)
    800042fa:	f0a2                	sd	s0,96(sp)
    800042fc:	eca6                	sd	s1,88(sp)
    800042fe:	e8ca                	sd	s2,80(sp)
    80004300:	e4ce                	sd	s3,72(sp)
    80004302:	e0d2                	sd	s4,64(sp)
    80004304:	fc56                	sd	s5,56(sp)
    80004306:	f85a                	sd	s6,48(sp)
    80004308:	f45e                	sd	s7,40(sp)
    8000430a:	f062                	sd	s8,32(sp)
    8000430c:	ec66                	sd	s9,24(sp)
    8000430e:	e86a                	sd	s10,16(sp)
    80004310:	e46e                	sd	s11,8(sp)
    80004312:	1880                	addi	s0,sp,112
    80004314:	8b2a                	mv	s6,a0
    80004316:	8c2e                	mv	s8,a1
    80004318:	8ab2                	mv	s5,a2
    8000431a:	8936                	mv	s2,a3
    8000431c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000431e:	00e687bb          	addw	a5,a3,a4
    80004322:	0ed7e263          	bltu	a5,a3,80004406 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004326:	00043737          	lui	a4,0x43
    8000432a:	0ef76063          	bltu	a4,a5,8000440a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000432e:	0c0b8863          	beqz	s7,800043fe <writei+0x10e>
    80004332:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004334:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004338:	5cfd                	li	s9,-1
    8000433a:	a091                	j	8000437e <writei+0x8e>
    8000433c:	02099d93          	slli	s11,s3,0x20
    80004340:	020ddd93          	srli	s11,s11,0x20
    80004344:	05848513          	addi	a0,s1,88
    80004348:	86ee                	mv	a3,s11
    8000434a:	8656                	mv	a2,s5
    8000434c:	85e2                	mv	a1,s8
    8000434e:	953a                	add	a0,a0,a4
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	90c080e7          	jalr	-1780(ra) # 80001c5c <either_copyin>
    80004358:	07950263          	beq	a0,s9,800043bc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000435c:	8526                	mv	a0,s1
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	790080e7          	jalr	1936(ra) # 80004aee <log_write>
    brelse(bp);
    80004366:	8526                	mv	a0,s1
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	50a080e7          	jalr	1290(ra) # 80003872 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004370:	01498a3b          	addw	s4,s3,s4
    80004374:	0129893b          	addw	s2,s3,s2
    80004378:	9aee                	add	s5,s5,s11
    8000437a:	057a7663          	bgeu	s4,s7,800043c6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000437e:	000b2483          	lw	s1,0(s6)
    80004382:	00a9559b          	srliw	a1,s2,0xa
    80004386:	855a                	mv	a0,s6
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	7ae080e7          	jalr	1966(ra) # 80003b36 <bmap>
    80004390:	0005059b          	sext.w	a1,a0
    80004394:	8526                	mv	a0,s1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	3ac080e7          	jalr	940(ra) # 80003742 <bread>
    8000439e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043a0:	3ff97713          	andi	a4,s2,1023
    800043a4:	40ed07bb          	subw	a5,s10,a4
    800043a8:	414b86bb          	subw	a3,s7,s4
    800043ac:	89be                	mv	s3,a5
    800043ae:	2781                	sext.w	a5,a5
    800043b0:	0006861b          	sext.w	a2,a3
    800043b4:	f8f674e3          	bgeu	a2,a5,8000433c <writei+0x4c>
    800043b8:	89b6                	mv	s3,a3
    800043ba:	b749                	j	8000433c <writei+0x4c>
      brelse(bp);
    800043bc:	8526                	mv	a0,s1
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	4b4080e7          	jalr	1204(ra) # 80003872 <brelse>
  }

  if(off > ip->size)
    800043c6:	04cb2783          	lw	a5,76(s6)
    800043ca:	0127f463          	bgeu	a5,s2,800043d2 <writei+0xe2>
    ip->size = off;
    800043ce:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043d2:	855a                	mv	a0,s6
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	aa6080e7          	jalr	-1370(ra) # 80003e7a <iupdate>

  return tot;
    800043dc:	000a051b          	sext.w	a0,s4
}
    800043e0:	70a6                	ld	ra,104(sp)
    800043e2:	7406                	ld	s0,96(sp)
    800043e4:	64e6                	ld	s1,88(sp)
    800043e6:	6946                	ld	s2,80(sp)
    800043e8:	69a6                	ld	s3,72(sp)
    800043ea:	6a06                	ld	s4,64(sp)
    800043ec:	7ae2                	ld	s5,56(sp)
    800043ee:	7b42                	ld	s6,48(sp)
    800043f0:	7ba2                	ld	s7,40(sp)
    800043f2:	7c02                	ld	s8,32(sp)
    800043f4:	6ce2                	ld	s9,24(sp)
    800043f6:	6d42                	ld	s10,16(sp)
    800043f8:	6da2                	ld	s11,8(sp)
    800043fa:	6165                	addi	sp,sp,112
    800043fc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043fe:	8a5e                	mv	s4,s7
    80004400:	bfc9                	j	800043d2 <writei+0xe2>
    return -1;
    80004402:	557d                	li	a0,-1
}
    80004404:	8082                	ret
    return -1;
    80004406:	557d                	li	a0,-1
    80004408:	bfe1                	j	800043e0 <writei+0xf0>
    return -1;
    8000440a:	557d                	li	a0,-1
    8000440c:	bfd1                	j	800043e0 <writei+0xf0>

000000008000440e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000440e:	1141                	addi	sp,sp,-16
    80004410:	e406                	sd	ra,8(sp)
    80004412:	e022                	sd	s0,0(sp)
    80004414:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004416:	4639                	li	a2,14
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	9a0080e7          	jalr	-1632(ra) # 80000db8 <strncmp>
}
    80004420:	60a2                	ld	ra,8(sp)
    80004422:	6402                	ld	s0,0(sp)
    80004424:	0141                	addi	sp,sp,16
    80004426:	8082                	ret

0000000080004428 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004428:	7139                	addi	sp,sp,-64
    8000442a:	fc06                	sd	ra,56(sp)
    8000442c:	f822                	sd	s0,48(sp)
    8000442e:	f426                	sd	s1,40(sp)
    80004430:	f04a                	sd	s2,32(sp)
    80004432:	ec4e                	sd	s3,24(sp)
    80004434:	e852                	sd	s4,16(sp)
    80004436:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004438:	04451703          	lh	a4,68(a0)
    8000443c:	4785                	li	a5,1
    8000443e:	00f71a63          	bne	a4,a5,80004452 <dirlookup+0x2a>
    80004442:	892a                	mv	s2,a0
    80004444:	89ae                	mv	s3,a1
    80004446:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004448:	457c                	lw	a5,76(a0)
    8000444a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000444c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444e:	e79d                	bnez	a5,8000447c <dirlookup+0x54>
    80004450:	a8a5                	j	800044c8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004452:	00004517          	auipc	a0,0x4
    80004456:	1ce50513          	addi	a0,a0,462 # 80008620 <syscalls+0x1b8>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	1d650513          	addi	a0,a0,470 # 80008638 <syscalls+0x1d0>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004472:	24c1                	addiw	s1,s1,16
    80004474:	04c92783          	lw	a5,76(s2)
    80004478:	04f4f763          	bgeu	s1,a5,800044c6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000447c:	4741                	li	a4,16
    8000447e:	86a6                	mv	a3,s1
    80004480:	fc040613          	addi	a2,s0,-64
    80004484:	4581                	li	a1,0
    80004486:	854a                	mv	a0,s2
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	d70080e7          	jalr	-656(ra) # 800041f8 <readi>
    80004490:	47c1                	li	a5,16
    80004492:	fcf518e3          	bne	a0,a5,80004462 <dirlookup+0x3a>
    if(de.inum == 0)
    80004496:	fc045783          	lhu	a5,-64(s0)
    8000449a:	dfe1                	beqz	a5,80004472 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000449c:	fc240593          	addi	a1,s0,-62
    800044a0:	854e                	mv	a0,s3
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	f6c080e7          	jalr	-148(ra) # 8000440e <namecmp>
    800044aa:	f561                	bnez	a0,80004472 <dirlookup+0x4a>
      if(poff)
    800044ac:	000a0463          	beqz	s4,800044b4 <dirlookup+0x8c>
        *poff = off;
    800044b0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800044b4:	fc045583          	lhu	a1,-64(s0)
    800044b8:	00092503          	lw	a0,0(s2)
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	754080e7          	jalr	1876(ra) # 80003c10 <iget>
    800044c4:	a011                	j	800044c8 <dirlookup+0xa0>
  return 0;
    800044c6:	4501                	li	a0,0
}
    800044c8:	70e2                	ld	ra,56(sp)
    800044ca:	7442                	ld	s0,48(sp)
    800044cc:	74a2                	ld	s1,40(sp)
    800044ce:	7902                	ld	s2,32(sp)
    800044d0:	69e2                	ld	s3,24(sp)
    800044d2:	6a42                	ld	s4,16(sp)
    800044d4:	6121                	addi	sp,sp,64
    800044d6:	8082                	ret

00000000800044d8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044d8:	711d                	addi	sp,sp,-96
    800044da:	ec86                	sd	ra,88(sp)
    800044dc:	e8a2                	sd	s0,80(sp)
    800044de:	e4a6                	sd	s1,72(sp)
    800044e0:	e0ca                	sd	s2,64(sp)
    800044e2:	fc4e                	sd	s3,56(sp)
    800044e4:	f852                	sd	s4,48(sp)
    800044e6:	f456                	sd	s5,40(sp)
    800044e8:	f05a                	sd	s6,32(sp)
    800044ea:	ec5e                	sd	s7,24(sp)
    800044ec:	e862                	sd	s8,16(sp)
    800044ee:	e466                	sd	s9,8(sp)
    800044f0:	1080                	addi	s0,sp,96
    800044f2:	84aa                	mv	s1,a0
    800044f4:	8b2e                	mv	s6,a1
    800044f6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044f8:	00054703          	lbu	a4,0(a0)
    800044fc:	02f00793          	li	a5,47
    80004500:	02f70363          	beq	a4,a5,80004526 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004504:	ffffd097          	auipc	ra,0xffffd
    80004508:	402080e7          	jalr	1026(ra) # 80001906 <myproc>
    8000450c:	17853503          	ld	a0,376(a0)
    80004510:	00000097          	auipc	ra,0x0
    80004514:	9f6080e7          	jalr	-1546(ra) # 80003f06 <idup>
    80004518:	89aa                	mv	s3,a0
  while(*path == '/')
    8000451a:	02f00913          	li	s2,47
  len = path - s;
    8000451e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004520:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004522:	4c05                	li	s8,1
    80004524:	a865                	j	800045dc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004526:	4585                	li	a1,1
    80004528:	4505                	li	a0,1
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	6e6080e7          	jalr	1766(ra) # 80003c10 <iget>
    80004532:	89aa                	mv	s3,a0
    80004534:	b7dd                	j	8000451a <namex+0x42>
      iunlockput(ip);
    80004536:	854e                	mv	a0,s3
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	c6e080e7          	jalr	-914(ra) # 800041a6 <iunlockput>
      return 0;
    80004540:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004542:	854e                	mv	a0,s3
    80004544:	60e6                	ld	ra,88(sp)
    80004546:	6446                	ld	s0,80(sp)
    80004548:	64a6                	ld	s1,72(sp)
    8000454a:	6906                	ld	s2,64(sp)
    8000454c:	79e2                	ld	s3,56(sp)
    8000454e:	7a42                	ld	s4,48(sp)
    80004550:	7aa2                	ld	s5,40(sp)
    80004552:	7b02                	ld	s6,32(sp)
    80004554:	6be2                	ld	s7,24(sp)
    80004556:	6c42                	ld	s8,16(sp)
    80004558:	6ca2                	ld	s9,8(sp)
    8000455a:	6125                	addi	sp,sp,96
    8000455c:	8082                	ret
      iunlock(ip);
    8000455e:	854e                	mv	a0,s3
    80004560:	00000097          	auipc	ra,0x0
    80004564:	aa6080e7          	jalr	-1370(ra) # 80004006 <iunlock>
      return ip;
    80004568:	bfe9                	j	80004542 <namex+0x6a>
      iunlockput(ip);
    8000456a:	854e                	mv	a0,s3
    8000456c:	00000097          	auipc	ra,0x0
    80004570:	c3a080e7          	jalr	-966(ra) # 800041a6 <iunlockput>
      return 0;
    80004574:	89d2                	mv	s3,s4
    80004576:	b7f1                	j	80004542 <namex+0x6a>
  len = path - s;
    80004578:	40b48633          	sub	a2,s1,a1
    8000457c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004580:	094cd463          	bge	s9,s4,80004608 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004584:	4639                	li	a2,14
    80004586:	8556                	mv	a0,s5
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	7b8080e7          	jalr	1976(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004590:	0004c783          	lbu	a5,0(s1)
    80004594:	01279763          	bne	a5,s2,800045a2 <namex+0xca>
    path++;
    80004598:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000459a:	0004c783          	lbu	a5,0(s1)
    8000459e:	ff278de3          	beq	a5,s2,80004598 <namex+0xc0>
    ilock(ip);
    800045a2:	854e                	mv	a0,s3
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	9a0080e7          	jalr	-1632(ra) # 80003f44 <ilock>
    if(ip->type != T_DIR){
    800045ac:	04499783          	lh	a5,68(s3)
    800045b0:	f98793e3          	bne	a5,s8,80004536 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800045b4:	000b0563          	beqz	s6,800045be <namex+0xe6>
    800045b8:	0004c783          	lbu	a5,0(s1)
    800045bc:	d3cd                	beqz	a5,8000455e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045be:	865e                	mv	a2,s7
    800045c0:	85d6                	mv	a1,s5
    800045c2:	854e                	mv	a0,s3
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	e64080e7          	jalr	-412(ra) # 80004428 <dirlookup>
    800045cc:	8a2a                	mv	s4,a0
    800045ce:	dd51                	beqz	a0,8000456a <namex+0x92>
    iunlockput(ip);
    800045d0:	854e                	mv	a0,s3
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	bd4080e7          	jalr	-1068(ra) # 800041a6 <iunlockput>
    ip = next;
    800045da:	89d2                	mv	s3,s4
  while(*path == '/')
    800045dc:	0004c783          	lbu	a5,0(s1)
    800045e0:	05279763          	bne	a5,s2,8000462e <namex+0x156>
    path++;
    800045e4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045e6:	0004c783          	lbu	a5,0(s1)
    800045ea:	ff278de3          	beq	a5,s2,800045e4 <namex+0x10c>
  if(*path == 0)
    800045ee:	c79d                	beqz	a5,8000461c <namex+0x144>
    path++;
    800045f0:	85a6                	mv	a1,s1
  len = path - s;
    800045f2:	8a5e                	mv	s4,s7
    800045f4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800045f6:	01278963          	beq	a5,s2,80004608 <namex+0x130>
    800045fa:	dfbd                	beqz	a5,80004578 <namex+0xa0>
    path++;
    800045fc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045fe:	0004c783          	lbu	a5,0(s1)
    80004602:	ff279ce3          	bne	a5,s2,800045fa <namex+0x122>
    80004606:	bf8d                	j	80004578 <namex+0xa0>
    memmove(name, s, len);
    80004608:	2601                	sext.w	a2,a2
    8000460a:	8556                	mv	a0,s5
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	734080e7          	jalr	1844(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004614:	9a56                	add	s4,s4,s5
    80004616:	000a0023          	sb	zero,0(s4)
    8000461a:	bf9d                	j	80004590 <namex+0xb8>
  if(nameiparent){
    8000461c:	f20b03e3          	beqz	s6,80004542 <namex+0x6a>
    iput(ip);
    80004620:	854e                	mv	a0,s3
    80004622:	00000097          	auipc	ra,0x0
    80004626:	adc080e7          	jalr	-1316(ra) # 800040fe <iput>
    return 0;
    8000462a:	4981                	li	s3,0
    8000462c:	bf19                	j	80004542 <namex+0x6a>
  if(*path == 0)
    8000462e:	d7fd                	beqz	a5,8000461c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004630:	0004c783          	lbu	a5,0(s1)
    80004634:	85a6                	mv	a1,s1
    80004636:	b7d1                	j	800045fa <namex+0x122>

0000000080004638 <dirlink>:
{
    80004638:	7139                	addi	sp,sp,-64
    8000463a:	fc06                	sd	ra,56(sp)
    8000463c:	f822                	sd	s0,48(sp)
    8000463e:	f426                	sd	s1,40(sp)
    80004640:	f04a                	sd	s2,32(sp)
    80004642:	ec4e                	sd	s3,24(sp)
    80004644:	e852                	sd	s4,16(sp)
    80004646:	0080                	addi	s0,sp,64
    80004648:	892a                	mv	s2,a0
    8000464a:	8a2e                	mv	s4,a1
    8000464c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000464e:	4601                	li	a2,0
    80004650:	00000097          	auipc	ra,0x0
    80004654:	dd8080e7          	jalr	-552(ra) # 80004428 <dirlookup>
    80004658:	e93d                	bnez	a0,800046ce <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000465a:	04c92483          	lw	s1,76(s2)
    8000465e:	c49d                	beqz	s1,8000468c <dirlink+0x54>
    80004660:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004662:	4741                	li	a4,16
    80004664:	86a6                	mv	a3,s1
    80004666:	fc040613          	addi	a2,s0,-64
    8000466a:	4581                	li	a1,0
    8000466c:	854a                	mv	a0,s2
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	b8a080e7          	jalr	-1142(ra) # 800041f8 <readi>
    80004676:	47c1                	li	a5,16
    80004678:	06f51163          	bne	a0,a5,800046da <dirlink+0xa2>
    if(de.inum == 0)
    8000467c:	fc045783          	lhu	a5,-64(s0)
    80004680:	c791                	beqz	a5,8000468c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004682:	24c1                	addiw	s1,s1,16
    80004684:	04c92783          	lw	a5,76(s2)
    80004688:	fcf4ede3          	bltu	s1,a5,80004662 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000468c:	4639                	li	a2,14
    8000468e:	85d2                	mv	a1,s4
    80004690:	fc240513          	addi	a0,s0,-62
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	760080e7          	jalr	1888(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000469c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046a0:	4741                	li	a4,16
    800046a2:	86a6                	mv	a3,s1
    800046a4:	fc040613          	addi	a2,s0,-64
    800046a8:	4581                	li	a1,0
    800046aa:	854a                	mv	a0,s2
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	c44080e7          	jalr	-956(ra) # 800042f0 <writei>
    800046b4:	872a                	mv	a4,a0
    800046b6:	47c1                	li	a5,16
  return 0;
    800046b8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046ba:	02f71863          	bne	a4,a5,800046ea <dirlink+0xb2>
}
    800046be:	70e2                	ld	ra,56(sp)
    800046c0:	7442                	ld	s0,48(sp)
    800046c2:	74a2                	ld	s1,40(sp)
    800046c4:	7902                	ld	s2,32(sp)
    800046c6:	69e2                	ld	s3,24(sp)
    800046c8:	6a42                	ld	s4,16(sp)
    800046ca:	6121                	addi	sp,sp,64
    800046cc:	8082                	ret
    iput(ip);
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	a30080e7          	jalr	-1488(ra) # 800040fe <iput>
    return -1;
    800046d6:	557d                	li	a0,-1
    800046d8:	b7dd                	j	800046be <dirlink+0x86>
      panic("dirlink read");
    800046da:	00004517          	auipc	a0,0x4
    800046de:	f6e50513          	addi	a0,a0,-146 # 80008648 <syscalls+0x1e0>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>
    panic("dirlink");
    800046ea:	00004517          	auipc	a0,0x4
    800046ee:	06e50513          	addi	a0,a0,110 # 80008758 <syscalls+0x2f0>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>

00000000800046fa <namei>:

struct inode*
namei(char *path)
{
    800046fa:	1101                	addi	sp,sp,-32
    800046fc:	ec06                	sd	ra,24(sp)
    800046fe:	e822                	sd	s0,16(sp)
    80004700:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004702:	fe040613          	addi	a2,s0,-32
    80004706:	4581                	li	a1,0
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	dd0080e7          	jalr	-560(ra) # 800044d8 <namex>
}
    80004710:	60e2                	ld	ra,24(sp)
    80004712:	6442                	ld	s0,16(sp)
    80004714:	6105                	addi	sp,sp,32
    80004716:	8082                	ret

0000000080004718 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004718:	1141                	addi	sp,sp,-16
    8000471a:	e406                	sd	ra,8(sp)
    8000471c:	e022                	sd	s0,0(sp)
    8000471e:	0800                	addi	s0,sp,16
    80004720:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004722:	4585                	li	a1,1
    80004724:	00000097          	auipc	ra,0x0
    80004728:	db4080e7          	jalr	-588(ra) # 800044d8 <namex>
}
    8000472c:	60a2                	ld	ra,8(sp)
    8000472e:	6402                	ld	s0,0(sp)
    80004730:	0141                	addi	sp,sp,16
    80004732:	8082                	ret

0000000080004734 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004734:	1101                	addi	sp,sp,-32
    80004736:	ec06                	sd	ra,24(sp)
    80004738:	e822                	sd	s0,16(sp)
    8000473a:	e426                	sd	s1,8(sp)
    8000473c:	e04a                	sd	s2,0(sp)
    8000473e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004740:	0001e917          	auipc	s2,0x1e
    80004744:	6a090913          	addi	s2,s2,1696 # 80022de0 <log>
    80004748:	01892583          	lw	a1,24(s2)
    8000474c:	02892503          	lw	a0,40(s2)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	ff2080e7          	jalr	-14(ra) # 80003742 <bread>
    80004758:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000475a:	02c92683          	lw	a3,44(s2)
    8000475e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004760:	02d05763          	blez	a3,8000478e <write_head+0x5a>
    80004764:	0001e797          	auipc	a5,0x1e
    80004768:	6ac78793          	addi	a5,a5,1708 # 80022e10 <log+0x30>
    8000476c:	05c50713          	addi	a4,a0,92
    80004770:	36fd                	addiw	a3,a3,-1
    80004772:	1682                	slli	a3,a3,0x20
    80004774:	9281                	srli	a3,a3,0x20
    80004776:	068a                	slli	a3,a3,0x2
    80004778:	0001e617          	auipc	a2,0x1e
    8000477c:	69c60613          	addi	a2,a2,1692 # 80022e14 <log+0x34>
    80004780:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004782:	4390                	lw	a2,0(a5)
    80004784:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004786:	0791                	addi	a5,a5,4
    80004788:	0711                	addi	a4,a4,4
    8000478a:	fed79ce3          	bne	a5,a3,80004782 <write_head+0x4e>
  }
  bwrite(buf);
    8000478e:	8526                	mv	a0,s1
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	0a4080e7          	jalr	164(ra) # 80003834 <bwrite>
  brelse(buf);
    80004798:	8526                	mv	a0,s1
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	0d8080e7          	jalr	216(ra) # 80003872 <brelse>
}
    800047a2:	60e2                	ld	ra,24(sp)
    800047a4:	6442                	ld	s0,16(sp)
    800047a6:	64a2                	ld	s1,8(sp)
    800047a8:	6902                	ld	s2,0(sp)
    800047aa:	6105                	addi	sp,sp,32
    800047ac:	8082                	ret

00000000800047ae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047ae:	0001e797          	auipc	a5,0x1e
    800047b2:	65e7a783          	lw	a5,1630(a5) # 80022e0c <log+0x2c>
    800047b6:	0af05d63          	blez	a5,80004870 <install_trans+0xc2>
{
    800047ba:	7139                	addi	sp,sp,-64
    800047bc:	fc06                	sd	ra,56(sp)
    800047be:	f822                	sd	s0,48(sp)
    800047c0:	f426                	sd	s1,40(sp)
    800047c2:	f04a                	sd	s2,32(sp)
    800047c4:	ec4e                	sd	s3,24(sp)
    800047c6:	e852                	sd	s4,16(sp)
    800047c8:	e456                	sd	s5,8(sp)
    800047ca:	e05a                	sd	s6,0(sp)
    800047cc:	0080                	addi	s0,sp,64
    800047ce:	8b2a                	mv	s6,a0
    800047d0:	0001ea97          	auipc	s5,0x1e
    800047d4:	640a8a93          	addi	s5,s5,1600 # 80022e10 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047da:	0001e997          	auipc	s3,0x1e
    800047de:	60698993          	addi	s3,s3,1542 # 80022de0 <log>
    800047e2:	a035                	j	8000480e <install_trans+0x60>
      bunpin(dbuf);
    800047e4:	8526                	mv	a0,s1
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	166080e7          	jalr	358(ra) # 8000394c <bunpin>
    brelse(lbuf);
    800047ee:	854a                	mv	a0,s2
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	082080e7          	jalr	130(ra) # 80003872 <brelse>
    brelse(dbuf);
    800047f8:	8526                	mv	a0,s1
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	078080e7          	jalr	120(ra) # 80003872 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004802:	2a05                	addiw	s4,s4,1
    80004804:	0a91                	addi	s5,s5,4
    80004806:	02c9a783          	lw	a5,44(s3)
    8000480a:	04fa5963          	bge	s4,a5,8000485c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000480e:	0189a583          	lw	a1,24(s3)
    80004812:	014585bb          	addw	a1,a1,s4
    80004816:	2585                	addiw	a1,a1,1
    80004818:	0289a503          	lw	a0,40(s3)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	f26080e7          	jalr	-218(ra) # 80003742 <bread>
    80004824:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004826:	000aa583          	lw	a1,0(s5)
    8000482a:	0289a503          	lw	a0,40(s3)
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	f14080e7          	jalr	-236(ra) # 80003742 <bread>
    80004836:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004838:	40000613          	li	a2,1024
    8000483c:	05890593          	addi	a1,s2,88
    80004840:	05850513          	addi	a0,a0,88
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	4fc080e7          	jalr	1276(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000484c:	8526                	mv	a0,s1
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	fe6080e7          	jalr	-26(ra) # 80003834 <bwrite>
    if(recovering == 0)
    80004856:	f80b1ce3          	bnez	s6,800047ee <install_trans+0x40>
    8000485a:	b769                	j	800047e4 <install_trans+0x36>
}
    8000485c:	70e2                	ld	ra,56(sp)
    8000485e:	7442                	ld	s0,48(sp)
    80004860:	74a2                	ld	s1,40(sp)
    80004862:	7902                	ld	s2,32(sp)
    80004864:	69e2                	ld	s3,24(sp)
    80004866:	6a42                	ld	s4,16(sp)
    80004868:	6aa2                	ld	s5,8(sp)
    8000486a:	6b02                	ld	s6,0(sp)
    8000486c:	6121                	addi	sp,sp,64
    8000486e:	8082                	ret
    80004870:	8082                	ret

0000000080004872 <initlog>:
{
    80004872:	7179                	addi	sp,sp,-48
    80004874:	f406                	sd	ra,40(sp)
    80004876:	f022                	sd	s0,32(sp)
    80004878:	ec26                	sd	s1,24(sp)
    8000487a:	e84a                	sd	s2,16(sp)
    8000487c:	e44e                	sd	s3,8(sp)
    8000487e:	1800                	addi	s0,sp,48
    80004880:	892a                	mv	s2,a0
    80004882:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004884:	0001e497          	auipc	s1,0x1e
    80004888:	55c48493          	addi	s1,s1,1372 # 80022de0 <log>
    8000488c:	00004597          	auipc	a1,0x4
    80004890:	dcc58593          	addi	a1,a1,-564 # 80008658 <syscalls+0x1f0>
    80004894:	8526                	mv	a0,s1
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	2be080e7          	jalr	702(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000489e:	0149a583          	lw	a1,20(s3)
    800048a2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048a4:	0109a783          	lw	a5,16(s3)
    800048a8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048aa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048ae:	854a                	mv	a0,s2
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	e92080e7          	jalr	-366(ra) # 80003742 <bread>
  log.lh.n = lh->n;
    800048b8:	4d3c                	lw	a5,88(a0)
    800048ba:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048bc:	02f05563          	blez	a5,800048e6 <initlog+0x74>
    800048c0:	05c50713          	addi	a4,a0,92
    800048c4:	0001e697          	auipc	a3,0x1e
    800048c8:	54c68693          	addi	a3,a3,1356 # 80022e10 <log+0x30>
    800048cc:	37fd                	addiw	a5,a5,-1
    800048ce:	1782                	slli	a5,a5,0x20
    800048d0:	9381                	srli	a5,a5,0x20
    800048d2:	078a                	slli	a5,a5,0x2
    800048d4:	06050613          	addi	a2,a0,96
    800048d8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800048da:	4310                	lw	a2,0(a4)
    800048dc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800048de:	0711                	addi	a4,a4,4
    800048e0:	0691                	addi	a3,a3,4
    800048e2:	fef71ce3          	bne	a4,a5,800048da <initlog+0x68>
  brelse(buf);
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	f8c080e7          	jalr	-116(ra) # 80003872 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048ee:	4505                	li	a0,1
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	ebe080e7          	jalr	-322(ra) # 800047ae <install_trans>
  log.lh.n = 0;
    800048f8:	0001e797          	auipc	a5,0x1e
    800048fc:	5007aa23          	sw	zero,1300(a5) # 80022e0c <log+0x2c>
  write_head(); // clear the log
    80004900:	00000097          	auipc	ra,0x0
    80004904:	e34080e7          	jalr	-460(ra) # 80004734 <write_head>
}
    80004908:	70a2                	ld	ra,40(sp)
    8000490a:	7402                	ld	s0,32(sp)
    8000490c:	64e2                	ld	s1,24(sp)
    8000490e:	6942                	ld	s2,16(sp)
    80004910:	69a2                	ld	s3,8(sp)
    80004912:	6145                	addi	sp,sp,48
    80004914:	8082                	ret

0000000080004916 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004916:	1101                	addi	sp,sp,-32
    80004918:	ec06                	sd	ra,24(sp)
    8000491a:	e822                	sd	s0,16(sp)
    8000491c:	e426                	sd	s1,8(sp)
    8000491e:	e04a                	sd	s2,0(sp)
    80004920:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004922:	0001e517          	auipc	a0,0x1e
    80004926:	4be50513          	addi	a0,a0,1214 # 80022de0 <log>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004932:	0001e497          	auipc	s1,0x1e
    80004936:	4ae48493          	addi	s1,s1,1198 # 80022de0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000493a:	4979                	li	s2,30
    8000493c:	a039                	j	8000494a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000493e:	85a6                	mv	a1,s1
    80004940:	8526                	mv	a0,s1
    80004942:	ffffd097          	auipc	ra,0xffffd
    80004946:	686080e7          	jalr	1670(ra) # 80001fc8 <sleep>
    if(log.committing){
    8000494a:	50dc                	lw	a5,36(s1)
    8000494c:	fbed                	bnez	a5,8000493e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000494e:	509c                	lw	a5,32(s1)
    80004950:	0017871b          	addiw	a4,a5,1
    80004954:	0007069b          	sext.w	a3,a4
    80004958:	0027179b          	slliw	a5,a4,0x2
    8000495c:	9fb9                	addw	a5,a5,a4
    8000495e:	0017979b          	slliw	a5,a5,0x1
    80004962:	54d8                	lw	a4,44(s1)
    80004964:	9fb9                	addw	a5,a5,a4
    80004966:	00f95963          	bge	s2,a5,80004978 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000496a:	85a6                	mv	a1,s1
    8000496c:	8526                	mv	a0,s1
    8000496e:	ffffd097          	auipc	ra,0xffffd
    80004972:	65a080e7          	jalr	1626(ra) # 80001fc8 <sleep>
    80004976:	bfd1                	j	8000494a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004978:	0001e517          	auipc	a0,0x1e
    8000497c:	46850513          	addi	a0,a0,1128 # 80022de0 <log>
    80004980:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	316080e7          	jalr	790(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004996:	7139                	addi	sp,sp,-64
    80004998:	fc06                	sd	ra,56(sp)
    8000499a:	f822                	sd	s0,48(sp)
    8000499c:	f426                	sd	s1,40(sp)
    8000499e:	f04a                	sd	s2,32(sp)
    800049a0:	ec4e                	sd	s3,24(sp)
    800049a2:	e852                	sd	s4,16(sp)
    800049a4:	e456                	sd	s5,8(sp)
    800049a6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049a8:	0001e497          	auipc	s1,0x1e
    800049ac:	43848493          	addi	s1,s1,1080 # 80022de0 <log>
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	232080e7          	jalr	562(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800049ba:	509c                	lw	a5,32(s1)
    800049bc:	37fd                	addiw	a5,a5,-1
    800049be:	0007891b          	sext.w	s2,a5
    800049c2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049c4:	50dc                	lw	a5,36(s1)
    800049c6:	efb9                	bnez	a5,80004a24 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049c8:	06091663          	bnez	s2,80004a34 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800049cc:	0001e497          	auipc	s1,0x1e
    800049d0:	41448493          	addi	s1,s1,1044 # 80022de0 <log>
    800049d4:	4785                	li	a5,1
    800049d6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	2be080e7          	jalr	702(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049e2:	54dc                	lw	a5,44(s1)
    800049e4:	06f04763          	bgtz	a5,80004a52 <end_op+0xbc>
    acquire(&log.lock);
    800049e8:	0001e497          	auipc	s1,0x1e
    800049ec:	3f848493          	addi	s1,s1,1016 # 80022de0 <log>
    800049f0:	8526                	mv	a0,s1
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
    log.committing = 0;
    800049fa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049fe:	8526                	mv	a0,s1
    80004a00:	ffffd097          	auipc	ra,0xffffd
    80004a04:	642080e7          	jalr	1602(ra) # 80002042 <wakeup>
    release(&log.lock);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	28e080e7          	jalr	654(ra) # 80000c98 <release>
}
    80004a12:	70e2                	ld	ra,56(sp)
    80004a14:	7442                	ld	s0,48(sp)
    80004a16:	74a2                	ld	s1,40(sp)
    80004a18:	7902                	ld	s2,32(sp)
    80004a1a:	69e2                	ld	s3,24(sp)
    80004a1c:	6a42                	ld	s4,16(sp)
    80004a1e:	6aa2                	ld	s5,8(sp)
    80004a20:	6121                	addi	sp,sp,64
    80004a22:	8082                	ret
    panic("log.committing");
    80004a24:	00004517          	auipc	a0,0x4
    80004a28:	c3c50513          	addi	a0,a0,-964 # 80008660 <syscalls+0x1f8>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    wakeup(&log);
    80004a34:	0001e497          	auipc	s1,0x1e
    80004a38:	3ac48493          	addi	s1,s1,940 # 80022de0 <log>
    80004a3c:	8526                	mv	a0,s1
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	604080e7          	jalr	1540(ra) # 80002042 <wakeup>
  release(&log.lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
  if(do_commit){
    80004a50:	b7c9                	j	80004a12 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a52:	0001ea97          	auipc	s5,0x1e
    80004a56:	3bea8a93          	addi	s5,s5,958 # 80022e10 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a5a:	0001ea17          	auipc	s4,0x1e
    80004a5e:	386a0a13          	addi	s4,s4,902 # 80022de0 <log>
    80004a62:	018a2583          	lw	a1,24(s4)
    80004a66:	012585bb          	addw	a1,a1,s2
    80004a6a:	2585                	addiw	a1,a1,1
    80004a6c:	028a2503          	lw	a0,40(s4)
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	cd2080e7          	jalr	-814(ra) # 80003742 <bread>
    80004a78:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a7a:	000aa583          	lw	a1,0(s5)
    80004a7e:	028a2503          	lw	a0,40(s4)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	cc0080e7          	jalr	-832(ra) # 80003742 <bread>
    80004a8a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a8c:	40000613          	li	a2,1024
    80004a90:	05850593          	addi	a1,a0,88
    80004a94:	05848513          	addi	a0,s1,88
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	2a8080e7          	jalr	680(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	d92080e7          	jalr	-622(ra) # 80003834 <bwrite>
    brelse(from);
    80004aaa:	854e                	mv	a0,s3
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	dc6080e7          	jalr	-570(ra) # 80003872 <brelse>
    brelse(to);
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	dbc080e7          	jalr	-580(ra) # 80003872 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004abe:	2905                	addiw	s2,s2,1
    80004ac0:	0a91                	addi	s5,s5,4
    80004ac2:	02ca2783          	lw	a5,44(s4)
    80004ac6:	f8f94ee3          	blt	s2,a5,80004a62 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	c6a080e7          	jalr	-918(ra) # 80004734 <write_head>
    install_trans(0); // Now install writes to home locations
    80004ad2:	4501                	li	a0,0
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	cda080e7          	jalr	-806(ra) # 800047ae <install_trans>
    log.lh.n = 0;
    80004adc:	0001e797          	auipc	a5,0x1e
    80004ae0:	3207a823          	sw	zero,816(a5) # 80022e0c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	c50080e7          	jalr	-944(ra) # 80004734 <write_head>
    80004aec:	bdf5                	j	800049e8 <end_op+0x52>

0000000080004aee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004aee:	1101                	addi	sp,sp,-32
    80004af0:	ec06                	sd	ra,24(sp)
    80004af2:	e822                	sd	s0,16(sp)
    80004af4:	e426                	sd	s1,8(sp)
    80004af6:	e04a                	sd	s2,0(sp)
    80004af8:	1000                	addi	s0,sp,32
    80004afa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004afc:	0001e917          	auipc	s2,0x1e
    80004b00:	2e490913          	addi	s2,s2,740 # 80022de0 <log>
    80004b04:	854a                	mv	a0,s2
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	0de080e7          	jalr	222(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b0e:	02c92603          	lw	a2,44(s2)
    80004b12:	47f5                	li	a5,29
    80004b14:	06c7c563          	blt	a5,a2,80004b7e <log_write+0x90>
    80004b18:	0001e797          	auipc	a5,0x1e
    80004b1c:	2e47a783          	lw	a5,740(a5) # 80022dfc <log+0x1c>
    80004b20:	37fd                	addiw	a5,a5,-1
    80004b22:	04f65e63          	bge	a2,a5,80004b7e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b26:	0001e797          	auipc	a5,0x1e
    80004b2a:	2da7a783          	lw	a5,730(a5) # 80022e00 <log+0x20>
    80004b2e:	06f05063          	blez	a5,80004b8e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b32:	4781                	li	a5,0
    80004b34:	06c05563          	blez	a2,80004b9e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b38:	44cc                	lw	a1,12(s1)
    80004b3a:	0001e717          	auipc	a4,0x1e
    80004b3e:	2d670713          	addi	a4,a4,726 # 80022e10 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b42:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b44:	4314                	lw	a3,0(a4)
    80004b46:	04b68c63          	beq	a3,a1,80004b9e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b4a:	2785                	addiw	a5,a5,1
    80004b4c:	0711                	addi	a4,a4,4
    80004b4e:	fef61be3          	bne	a2,a5,80004b44 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b52:	0621                	addi	a2,a2,8
    80004b54:	060a                	slli	a2,a2,0x2
    80004b56:	0001e797          	auipc	a5,0x1e
    80004b5a:	28a78793          	addi	a5,a5,650 # 80022de0 <log>
    80004b5e:	963e                	add	a2,a2,a5
    80004b60:	44dc                	lw	a5,12(s1)
    80004b62:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b64:	8526                	mv	a0,s1
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	daa080e7          	jalr	-598(ra) # 80003910 <bpin>
    log.lh.n++;
    80004b6e:	0001e717          	auipc	a4,0x1e
    80004b72:	27270713          	addi	a4,a4,626 # 80022de0 <log>
    80004b76:	575c                	lw	a5,44(a4)
    80004b78:	2785                	addiw	a5,a5,1
    80004b7a:	d75c                	sw	a5,44(a4)
    80004b7c:	a835                	j	80004bb8 <log_write+0xca>
    panic("too big a transaction");
    80004b7e:	00004517          	auipc	a0,0x4
    80004b82:	af250513          	addi	a0,a0,-1294 # 80008670 <syscalls+0x208>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	9b8080e7          	jalr	-1608(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b8e:	00004517          	auipc	a0,0x4
    80004b92:	afa50513          	addi	a0,a0,-1286 # 80008688 <syscalls+0x220>
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	9a8080e7          	jalr	-1624(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b9e:	00878713          	addi	a4,a5,8
    80004ba2:	00271693          	slli	a3,a4,0x2
    80004ba6:	0001e717          	auipc	a4,0x1e
    80004baa:	23a70713          	addi	a4,a4,570 # 80022de0 <log>
    80004bae:	9736                	add	a4,a4,a3
    80004bb0:	44d4                	lw	a3,12(s1)
    80004bb2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bb4:	faf608e3          	beq	a2,a5,80004b64 <log_write+0x76>
  }
  release(&log.lock);
    80004bb8:	0001e517          	auipc	a0,0x1e
    80004bbc:	22850513          	addi	a0,a0,552 # 80022de0 <log>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	0d8080e7          	jalr	216(ra) # 80000c98 <release>
}
    80004bc8:	60e2                	ld	ra,24(sp)
    80004bca:	6442                	ld	s0,16(sp)
    80004bcc:	64a2                	ld	s1,8(sp)
    80004bce:	6902                	ld	s2,0(sp)
    80004bd0:	6105                	addi	sp,sp,32
    80004bd2:	8082                	ret

0000000080004bd4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bd4:	1101                	addi	sp,sp,-32
    80004bd6:	ec06                	sd	ra,24(sp)
    80004bd8:	e822                	sd	s0,16(sp)
    80004bda:	e426                	sd	s1,8(sp)
    80004bdc:	e04a                	sd	s2,0(sp)
    80004bde:	1000                	addi	s0,sp,32
    80004be0:	84aa                	mv	s1,a0
    80004be2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004be4:	00004597          	auipc	a1,0x4
    80004be8:	ac458593          	addi	a1,a1,-1340 # 800086a8 <syscalls+0x240>
    80004bec:	0521                	addi	a0,a0,8
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	f66080e7          	jalr	-154(ra) # 80000b54 <initlock>
  lk->name = name;
    80004bf6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004bfa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bfe:	0204a423          	sw	zero,40(s1)
}
    80004c02:	60e2                	ld	ra,24(sp)
    80004c04:	6442                	ld	s0,16(sp)
    80004c06:	64a2                	ld	s1,8(sp)
    80004c08:	6902                	ld	s2,0(sp)
    80004c0a:	6105                	addi	sp,sp,32
    80004c0c:	8082                	ret

0000000080004c0e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c0e:	1101                	addi	sp,sp,-32
    80004c10:	ec06                	sd	ra,24(sp)
    80004c12:	e822                	sd	s0,16(sp)
    80004c14:	e426                	sd	s1,8(sp)
    80004c16:	e04a                	sd	s2,0(sp)
    80004c18:	1000                	addi	s0,sp,32
    80004c1a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c1c:	00850913          	addi	s2,a0,8
    80004c20:	854a                	mv	a0,s2
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc2080e7          	jalr	-62(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004c2a:	409c                	lw	a5,0(s1)
    80004c2c:	cb89                	beqz	a5,80004c3e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c2e:	85ca                	mv	a1,s2
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	396080e7          	jalr	918(ra) # 80001fc8 <sleep>
  while (lk->locked) {
    80004c3a:	409c                	lw	a5,0(s1)
    80004c3c:	fbed                	bnez	a5,80004c2e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c3e:	4785                	li	a5,1
    80004c40:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	cc4080e7          	jalr	-828(ra) # 80001906 <myproc>
    80004c4a:	591c                	lw	a5,48(a0)
    80004c4c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c4e:	854a                	mv	a0,s2
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	048080e7          	jalr	72(ra) # 80000c98 <release>
}
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6902                	ld	s2,0(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret

0000000080004c64 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c64:	1101                	addi	sp,sp,-32
    80004c66:	ec06                	sd	ra,24(sp)
    80004c68:	e822                	sd	s0,16(sp)
    80004c6a:	e426                	sd	s1,8(sp)
    80004c6c:	e04a                	sd	s2,0(sp)
    80004c6e:	1000                	addi	s0,sp,32
    80004c70:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c72:	00850913          	addi	s2,a0,8
    80004c76:	854a                	mv	a0,s2
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	f6c080e7          	jalr	-148(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004c80:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c84:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffd097          	auipc	ra,0xffffd
    80004c8e:	3b8080e7          	jalr	952(ra) # 80002042 <wakeup>
  release(&lk->lk);
    80004c92:	854a                	mv	a0,s2
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	004080e7          	jalr	4(ra) # 80000c98 <release>
}
    80004c9c:	60e2                	ld	ra,24(sp)
    80004c9e:	6442                	ld	s0,16(sp)
    80004ca0:	64a2                	ld	s1,8(sp)
    80004ca2:	6902                	ld	s2,0(sp)
    80004ca4:	6105                	addi	sp,sp,32
    80004ca6:	8082                	ret

0000000080004ca8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ca8:	7179                	addi	sp,sp,-48
    80004caa:	f406                	sd	ra,40(sp)
    80004cac:	f022                	sd	s0,32(sp)
    80004cae:	ec26                	sd	s1,24(sp)
    80004cb0:	e84a                	sd	s2,16(sp)
    80004cb2:	e44e                	sd	s3,8(sp)
    80004cb4:	1800                	addi	s0,sp,48
    80004cb6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cb8:	00850913          	addi	s2,a0,8
    80004cbc:	854a                	mv	a0,s2
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f26080e7          	jalr	-218(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cc6:	409c                	lw	a5,0(s1)
    80004cc8:	ef99                	bnez	a5,80004ce6 <holdingsleep+0x3e>
    80004cca:	4481                	li	s1,0
  release(&lk->lk);
    80004ccc:	854a                	mv	a0,s2
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	fca080e7          	jalr	-54(ra) # 80000c98 <release>
  return r;
}
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	70a2                	ld	ra,40(sp)
    80004cda:	7402                	ld	s0,32(sp)
    80004cdc:	64e2                	ld	s1,24(sp)
    80004cde:	6942                	ld	s2,16(sp)
    80004ce0:	69a2                	ld	s3,8(sp)
    80004ce2:	6145                	addi	sp,sp,48
    80004ce4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ce6:	0284a983          	lw	s3,40(s1)
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	c1c080e7          	jalr	-996(ra) # 80001906 <myproc>
    80004cf2:	5904                	lw	s1,48(a0)
    80004cf4:	413484b3          	sub	s1,s1,s3
    80004cf8:	0014b493          	seqz	s1,s1
    80004cfc:	bfc1                	j	80004ccc <holdingsleep+0x24>

0000000080004cfe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004cfe:	1141                	addi	sp,sp,-16
    80004d00:	e406                	sd	ra,8(sp)
    80004d02:	e022                	sd	s0,0(sp)
    80004d04:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d06:	00004597          	auipc	a1,0x4
    80004d0a:	9b258593          	addi	a1,a1,-1614 # 800086b8 <syscalls+0x250>
    80004d0e:	0001e517          	auipc	a0,0x1e
    80004d12:	21a50513          	addi	a0,a0,538 # 80022f28 <ftable>
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	e3e080e7          	jalr	-450(ra) # 80000b54 <initlock>
}
    80004d1e:	60a2                	ld	ra,8(sp)
    80004d20:	6402                	ld	s0,0(sp)
    80004d22:	0141                	addi	sp,sp,16
    80004d24:	8082                	ret

0000000080004d26 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d26:	1101                	addi	sp,sp,-32
    80004d28:	ec06                	sd	ra,24(sp)
    80004d2a:	e822                	sd	s0,16(sp)
    80004d2c:	e426                	sd	s1,8(sp)
    80004d2e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d30:	0001e517          	auipc	a0,0x1e
    80004d34:	1f850513          	addi	a0,a0,504 # 80022f28 <ftable>
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	eac080e7          	jalr	-340(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d40:	0001e497          	auipc	s1,0x1e
    80004d44:	20048493          	addi	s1,s1,512 # 80022f40 <ftable+0x18>
    80004d48:	0001f717          	auipc	a4,0x1f
    80004d4c:	19870713          	addi	a4,a4,408 # 80023ee0 <ftable+0xfb8>
    if(f->ref == 0){
    80004d50:	40dc                	lw	a5,4(s1)
    80004d52:	cf99                	beqz	a5,80004d70 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d54:	02848493          	addi	s1,s1,40
    80004d58:	fee49ce3          	bne	s1,a4,80004d50 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d5c:	0001e517          	auipc	a0,0x1e
    80004d60:	1cc50513          	addi	a0,a0,460 # 80022f28 <ftable>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f34080e7          	jalr	-204(ra) # 80000c98 <release>
  return 0;
    80004d6c:	4481                	li	s1,0
    80004d6e:	a819                	j	80004d84 <filealloc+0x5e>
      f->ref = 1;
    80004d70:	4785                	li	a5,1
    80004d72:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d74:	0001e517          	auipc	a0,0x1e
    80004d78:	1b450513          	addi	a0,a0,436 # 80022f28 <ftable>
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	f1c080e7          	jalr	-228(ra) # 80000c98 <release>
}
    80004d84:	8526                	mv	a0,s1
    80004d86:	60e2                	ld	ra,24(sp)
    80004d88:	6442                	ld	s0,16(sp)
    80004d8a:	64a2                	ld	s1,8(sp)
    80004d8c:	6105                	addi	sp,sp,32
    80004d8e:	8082                	ret

0000000080004d90 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d90:	1101                	addi	sp,sp,-32
    80004d92:	ec06                	sd	ra,24(sp)
    80004d94:	e822                	sd	s0,16(sp)
    80004d96:	e426                	sd	s1,8(sp)
    80004d98:	1000                	addi	s0,sp,32
    80004d9a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d9c:	0001e517          	auipc	a0,0x1e
    80004da0:	18c50513          	addi	a0,a0,396 # 80022f28 <ftable>
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e40080e7          	jalr	-448(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004dac:	40dc                	lw	a5,4(s1)
    80004dae:	02f05263          	blez	a5,80004dd2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004db2:	2785                	addiw	a5,a5,1
    80004db4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004db6:	0001e517          	auipc	a0,0x1e
    80004dba:	17250513          	addi	a0,a0,370 # 80022f28 <ftable>
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
  return f;
}
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	60e2                	ld	ra,24(sp)
    80004dca:	6442                	ld	s0,16(sp)
    80004dcc:	64a2                	ld	s1,8(sp)
    80004dce:	6105                	addi	sp,sp,32
    80004dd0:	8082                	ret
    panic("filedup");
    80004dd2:	00004517          	auipc	a0,0x4
    80004dd6:	8ee50513          	addi	a0,a0,-1810 # 800086c0 <syscalls+0x258>
    80004dda:	ffffb097          	auipc	ra,0xffffb
    80004dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080004de2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004de2:	7139                	addi	sp,sp,-64
    80004de4:	fc06                	sd	ra,56(sp)
    80004de6:	f822                	sd	s0,48(sp)
    80004de8:	f426                	sd	s1,40(sp)
    80004dea:	f04a                	sd	s2,32(sp)
    80004dec:	ec4e                	sd	s3,24(sp)
    80004dee:	e852                	sd	s4,16(sp)
    80004df0:	e456                	sd	s5,8(sp)
    80004df2:	0080                	addi	s0,sp,64
    80004df4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004df6:	0001e517          	auipc	a0,0x1e
    80004dfa:	13250513          	addi	a0,a0,306 # 80022f28 <ftable>
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	de6080e7          	jalr	-538(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e06:	40dc                	lw	a5,4(s1)
    80004e08:	06f05163          	blez	a5,80004e6a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e0c:	37fd                	addiw	a5,a5,-1
    80004e0e:	0007871b          	sext.w	a4,a5
    80004e12:	c0dc                	sw	a5,4(s1)
    80004e14:	06e04363          	bgtz	a4,80004e7a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e18:	0004a903          	lw	s2,0(s1)
    80004e1c:	0094ca83          	lbu	s5,9(s1)
    80004e20:	0104ba03          	ld	s4,16(s1)
    80004e24:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e28:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e2c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e30:	0001e517          	auipc	a0,0x1e
    80004e34:	0f850513          	addi	a0,a0,248 # 80022f28 <ftable>
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004e40:	4785                	li	a5,1
    80004e42:	04f90d63          	beq	s2,a5,80004e9c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e46:	3979                	addiw	s2,s2,-2
    80004e48:	4785                	li	a5,1
    80004e4a:	0527e063          	bltu	a5,s2,80004e8a <fileclose+0xa8>
    begin_op();
    80004e4e:	00000097          	auipc	ra,0x0
    80004e52:	ac8080e7          	jalr	-1336(ra) # 80004916 <begin_op>
    iput(ff.ip);
    80004e56:	854e                	mv	a0,s3
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	2a6080e7          	jalr	678(ra) # 800040fe <iput>
    end_op();
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	b36080e7          	jalr	-1226(ra) # 80004996 <end_op>
    80004e68:	a00d                	j	80004e8a <fileclose+0xa8>
    panic("fileclose");
    80004e6a:	00004517          	auipc	a0,0x4
    80004e6e:	85e50513          	addi	a0,a0,-1954 # 800086c8 <syscalls+0x260>
    80004e72:	ffffb097          	auipc	ra,0xffffb
    80004e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e7a:	0001e517          	auipc	a0,0x1e
    80004e7e:	0ae50513          	addi	a0,a0,174 # 80022f28 <ftable>
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  }
}
    80004e8a:	70e2                	ld	ra,56(sp)
    80004e8c:	7442                	ld	s0,48(sp)
    80004e8e:	74a2                	ld	s1,40(sp)
    80004e90:	7902                	ld	s2,32(sp)
    80004e92:	69e2                	ld	s3,24(sp)
    80004e94:	6a42                	ld	s4,16(sp)
    80004e96:	6aa2                	ld	s5,8(sp)
    80004e98:	6121                	addi	sp,sp,64
    80004e9a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e9c:	85d6                	mv	a1,s5
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	34c080e7          	jalr	844(ra) # 800051ec <pipeclose>
    80004ea8:	b7cd                	j	80004e8a <fileclose+0xa8>

0000000080004eaa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004eaa:	715d                	addi	sp,sp,-80
    80004eac:	e486                	sd	ra,72(sp)
    80004eae:	e0a2                	sd	s0,64(sp)
    80004eb0:	fc26                	sd	s1,56(sp)
    80004eb2:	f84a                	sd	s2,48(sp)
    80004eb4:	f44e                	sd	s3,40(sp)
    80004eb6:	0880                	addi	s0,sp,80
    80004eb8:	84aa                	mv	s1,a0
    80004eba:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	a4a080e7          	jalr	-1462(ra) # 80001906 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ec4:	409c                	lw	a5,0(s1)
    80004ec6:	37f9                	addiw	a5,a5,-2
    80004ec8:	4705                	li	a4,1
    80004eca:	04f76763          	bltu	a4,a5,80004f18 <filestat+0x6e>
    80004ece:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ed0:	6c88                	ld	a0,24(s1)
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	072080e7          	jalr	114(ra) # 80003f44 <ilock>
    stati(f->ip, &st);
    80004eda:	fb840593          	addi	a1,s0,-72
    80004ede:	6c88                	ld	a0,24(s1)
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	2ee080e7          	jalr	750(ra) # 800041ce <stati>
    iunlock(f->ip);
    80004ee8:	6c88                	ld	a0,24(s1)
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	11c080e7          	jalr	284(ra) # 80004006 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ef2:	46e1                	li	a3,24
    80004ef4:	fb840613          	addi	a2,s0,-72
    80004ef8:	85ce                	mv	a1,s3
    80004efa:	07893503          	ld	a0,120(s2)
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	774080e7          	jalr	1908(ra) # 80001672 <copyout>
    80004f06:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f0a:	60a6                	ld	ra,72(sp)
    80004f0c:	6406                	ld	s0,64(sp)
    80004f0e:	74e2                	ld	s1,56(sp)
    80004f10:	7942                	ld	s2,48(sp)
    80004f12:	79a2                	ld	s3,40(sp)
    80004f14:	6161                	addi	sp,sp,80
    80004f16:	8082                	ret
  return -1;
    80004f18:	557d                	li	a0,-1
    80004f1a:	bfc5                	j	80004f0a <filestat+0x60>

0000000080004f1c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f1c:	7179                	addi	sp,sp,-48
    80004f1e:	f406                	sd	ra,40(sp)
    80004f20:	f022                	sd	s0,32(sp)
    80004f22:	ec26                	sd	s1,24(sp)
    80004f24:	e84a                	sd	s2,16(sp)
    80004f26:	e44e                	sd	s3,8(sp)
    80004f28:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f2a:	00854783          	lbu	a5,8(a0)
    80004f2e:	c3d5                	beqz	a5,80004fd2 <fileread+0xb6>
    80004f30:	84aa                	mv	s1,a0
    80004f32:	89ae                	mv	s3,a1
    80004f34:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f36:	411c                	lw	a5,0(a0)
    80004f38:	4705                	li	a4,1
    80004f3a:	04e78963          	beq	a5,a4,80004f8c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f3e:	470d                	li	a4,3
    80004f40:	04e78d63          	beq	a5,a4,80004f9a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f44:	4709                	li	a4,2
    80004f46:	06e79e63          	bne	a5,a4,80004fc2 <fileread+0xa6>
    ilock(f->ip);
    80004f4a:	6d08                	ld	a0,24(a0)
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	ff8080e7          	jalr	-8(ra) # 80003f44 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f54:	874a                	mv	a4,s2
    80004f56:	5094                	lw	a3,32(s1)
    80004f58:	864e                	mv	a2,s3
    80004f5a:	4585                	li	a1,1
    80004f5c:	6c88                	ld	a0,24(s1)
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	29a080e7          	jalr	666(ra) # 800041f8 <readi>
    80004f66:	892a                	mv	s2,a0
    80004f68:	00a05563          	blez	a0,80004f72 <fileread+0x56>
      f->off += r;
    80004f6c:	509c                	lw	a5,32(s1)
    80004f6e:	9fa9                	addw	a5,a5,a0
    80004f70:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f72:	6c88                	ld	a0,24(s1)
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	092080e7          	jalr	146(ra) # 80004006 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f7c:	854a                	mv	a0,s2
    80004f7e:	70a2                	ld	ra,40(sp)
    80004f80:	7402                	ld	s0,32(sp)
    80004f82:	64e2                	ld	s1,24(sp)
    80004f84:	6942                	ld	s2,16(sp)
    80004f86:	69a2                	ld	s3,8(sp)
    80004f88:	6145                	addi	sp,sp,48
    80004f8a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f8c:	6908                	ld	a0,16(a0)
    80004f8e:	00000097          	auipc	ra,0x0
    80004f92:	3c8080e7          	jalr	968(ra) # 80005356 <piperead>
    80004f96:	892a                	mv	s2,a0
    80004f98:	b7d5                	j	80004f7c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f9a:	02451783          	lh	a5,36(a0)
    80004f9e:	03079693          	slli	a3,a5,0x30
    80004fa2:	92c1                	srli	a3,a3,0x30
    80004fa4:	4725                	li	a4,9
    80004fa6:	02d76863          	bltu	a4,a3,80004fd6 <fileread+0xba>
    80004faa:	0792                	slli	a5,a5,0x4
    80004fac:	0001e717          	auipc	a4,0x1e
    80004fb0:	edc70713          	addi	a4,a4,-292 # 80022e88 <devsw>
    80004fb4:	97ba                	add	a5,a5,a4
    80004fb6:	639c                	ld	a5,0(a5)
    80004fb8:	c38d                	beqz	a5,80004fda <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fba:	4505                	li	a0,1
    80004fbc:	9782                	jalr	a5
    80004fbe:	892a                	mv	s2,a0
    80004fc0:	bf75                	j	80004f7c <fileread+0x60>
    panic("fileread");
    80004fc2:	00003517          	auipc	a0,0x3
    80004fc6:	71650513          	addi	a0,a0,1814 # 800086d8 <syscalls+0x270>
    80004fca:	ffffb097          	auipc	ra,0xffffb
    80004fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>
    return -1;
    80004fd2:	597d                	li	s2,-1
    80004fd4:	b765                	j	80004f7c <fileread+0x60>
      return -1;
    80004fd6:	597d                	li	s2,-1
    80004fd8:	b755                	j	80004f7c <fileread+0x60>
    80004fda:	597d                	li	s2,-1
    80004fdc:	b745                	j	80004f7c <fileread+0x60>

0000000080004fde <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004fde:	715d                	addi	sp,sp,-80
    80004fe0:	e486                	sd	ra,72(sp)
    80004fe2:	e0a2                	sd	s0,64(sp)
    80004fe4:	fc26                	sd	s1,56(sp)
    80004fe6:	f84a                	sd	s2,48(sp)
    80004fe8:	f44e                	sd	s3,40(sp)
    80004fea:	f052                	sd	s4,32(sp)
    80004fec:	ec56                	sd	s5,24(sp)
    80004fee:	e85a                	sd	s6,16(sp)
    80004ff0:	e45e                	sd	s7,8(sp)
    80004ff2:	e062                	sd	s8,0(sp)
    80004ff4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ff6:	00954783          	lbu	a5,9(a0)
    80004ffa:	10078663          	beqz	a5,80005106 <filewrite+0x128>
    80004ffe:	892a                	mv	s2,a0
    80005000:	8aae                	mv	s5,a1
    80005002:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005004:	411c                	lw	a5,0(a0)
    80005006:	4705                	li	a4,1
    80005008:	02e78263          	beq	a5,a4,8000502c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000500c:	470d                	li	a4,3
    8000500e:	02e78663          	beq	a5,a4,8000503a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005012:	4709                	li	a4,2
    80005014:	0ee79163          	bne	a5,a4,800050f6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005018:	0ac05d63          	blez	a2,800050d2 <filewrite+0xf4>
    int i = 0;
    8000501c:	4981                	li	s3,0
    8000501e:	6b05                	lui	s6,0x1
    80005020:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005024:	6b85                	lui	s7,0x1
    80005026:	c00b8b9b          	addiw	s7,s7,-1024
    8000502a:	a861                	j	800050c2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000502c:	6908                	ld	a0,16(a0)
    8000502e:	00000097          	auipc	ra,0x0
    80005032:	22e080e7          	jalr	558(ra) # 8000525c <pipewrite>
    80005036:	8a2a                	mv	s4,a0
    80005038:	a045                	j	800050d8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000503a:	02451783          	lh	a5,36(a0)
    8000503e:	03079693          	slli	a3,a5,0x30
    80005042:	92c1                	srli	a3,a3,0x30
    80005044:	4725                	li	a4,9
    80005046:	0cd76263          	bltu	a4,a3,8000510a <filewrite+0x12c>
    8000504a:	0792                	slli	a5,a5,0x4
    8000504c:	0001e717          	auipc	a4,0x1e
    80005050:	e3c70713          	addi	a4,a4,-452 # 80022e88 <devsw>
    80005054:	97ba                	add	a5,a5,a4
    80005056:	679c                	ld	a5,8(a5)
    80005058:	cbdd                	beqz	a5,8000510e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000505a:	4505                	li	a0,1
    8000505c:	9782                	jalr	a5
    8000505e:	8a2a                	mv	s4,a0
    80005060:	a8a5                	j	800050d8 <filewrite+0xfa>
    80005062:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005066:	00000097          	auipc	ra,0x0
    8000506a:	8b0080e7          	jalr	-1872(ra) # 80004916 <begin_op>
      ilock(f->ip);
    8000506e:	01893503          	ld	a0,24(s2)
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	ed2080e7          	jalr	-302(ra) # 80003f44 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000507a:	8762                	mv	a4,s8
    8000507c:	02092683          	lw	a3,32(s2)
    80005080:	01598633          	add	a2,s3,s5
    80005084:	4585                	li	a1,1
    80005086:	01893503          	ld	a0,24(s2)
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	266080e7          	jalr	614(ra) # 800042f0 <writei>
    80005092:	84aa                	mv	s1,a0
    80005094:	00a05763          	blez	a0,800050a2 <filewrite+0xc4>
        f->off += r;
    80005098:	02092783          	lw	a5,32(s2)
    8000509c:	9fa9                	addw	a5,a5,a0
    8000509e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050a2:	01893503          	ld	a0,24(s2)
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	f60080e7          	jalr	-160(ra) # 80004006 <iunlock>
      end_op();
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	8e8080e7          	jalr	-1816(ra) # 80004996 <end_op>

      if(r != n1){
    800050b6:	009c1f63          	bne	s8,s1,800050d4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050ba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050be:	0149db63          	bge	s3,s4,800050d4 <filewrite+0xf6>
      int n1 = n - i;
    800050c2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050c6:	84be                	mv	s1,a5
    800050c8:	2781                	sext.w	a5,a5
    800050ca:	f8fb5ce3          	bge	s6,a5,80005062 <filewrite+0x84>
    800050ce:	84de                	mv	s1,s7
    800050d0:	bf49                	j	80005062 <filewrite+0x84>
    int i = 0;
    800050d2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050d4:	013a1f63          	bne	s4,s3,800050f2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050d8:	8552                	mv	a0,s4
    800050da:	60a6                	ld	ra,72(sp)
    800050dc:	6406                	ld	s0,64(sp)
    800050de:	74e2                	ld	s1,56(sp)
    800050e0:	7942                	ld	s2,48(sp)
    800050e2:	79a2                	ld	s3,40(sp)
    800050e4:	7a02                	ld	s4,32(sp)
    800050e6:	6ae2                	ld	s5,24(sp)
    800050e8:	6b42                	ld	s6,16(sp)
    800050ea:	6ba2                	ld	s7,8(sp)
    800050ec:	6c02                	ld	s8,0(sp)
    800050ee:	6161                	addi	sp,sp,80
    800050f0:	8082                	ret
    ret = (i == n ? n : -1);
    800050f2:	5a7d                	li	s4,-1
    800050f4:	b7d5                	j	800050d8 <filewrite+0xfa>
    panic("filewrite");
    800050f6:	00003517          	auipc	a0,0x3
    800050fa:	5f250513          	addi	a0,a0,1522 # 800086e8 <syscalls+0x280>
    800050fe:	ffffb097          	auipc	ra,0xffffb
    80005102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    return -1;
    80005106:	5a7d                	li	s4,-1
    80005108:	bfc1                	j	800050d8 <filewrite+0xfa>
      return -1;
    8000510a:	5a7d                	li	s4,-1
    8000510c:	b7f1                	j	800050d8 <filewrite+0xfa>
    8000510e:	5a7d                	li	s4,-1
    80005110:	b7e1                	j	800050d8 <filewrite+0xfa>

0000000080005112 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005112:	7179                	addi	sp,sp,-48
    80005114:	f406                	sd	ra,40(sp)
    80005116:	f022                	sd	s0,32(sp)
    80005118:	ec26                	sd	s1,24(sp)
    8000511a:	e84a                	sd	s2,16(sp)
    8000511c:	e44e                	sd	s3,8(sp)
    8000511e:	e052                	sd	s4,0(sp)
    80005120:	1800                	addi	s0,sp,48
    80005122:	84aa                	mv	s1,a0
    80005124:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005126:	0005b023          	sd	zero,0(a1)
    8000512a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	bf8080e7          	jalr	-1032(ra) # 80004d26 <filealloc>
    80005136:	e088                	sd	a0,0(s1)
    80005138:	c551                	beqz	a0,800051c4 <pipealloc+0xb2>
    8000513a:	00000097          	auipc	ra,0x0
    8000513e:	bec080e7          	jalr	-1044(ra) # 80004d26 <filealloc>
    80005142:	00aa3023          	sd	a0,0(s4)
    80005146:	c92d                	beqz	a0,800051b8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	9ac080e7          	jalr	-1620(ra) # 80000af4 <kalloc>
    80005150:	892a                	mv	s2,a0
    80005152:	c125                	beqz	a0,800051b2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005154:	4985                	li	s3,1
    80005156:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000515a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000515e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005162:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005166:	00003597          	auipc	a1,0x3
    8000516a:	59258593          	addi	a1,a1,1426 # 800086f8 <syscalls+0x290>
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	9e6080e7          	jalr	-1562(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005176:	609c                	ld	a5,0(s1)
    80005178:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000517c:	609c                	ld	a5,0(s1)
    8000517e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005182:	609c                	ld	a5,0(s1)
    80005184:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005188:	609c                	ld	a5,0(s1)
    8000518a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000518e:	000a3783          	ld	a5,0(s4)
    80005192:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005196:	000a3783          	ld	a5,0(s4)
    8000519a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000519e:	000a3783          	ld	a5,0(s4)
    800051a2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800051a6:	000a3783          	ld	a5,0(s4)
    800051aa:	0127b823          	sd	s2,16(a5)
  return 0;
    800051ae:	4501                	li	a0,0
    800051b0:	a025                	j	800051d8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051b2:	6088                	ld	a0,0(s1)
    800051b4:	e501                	bnez	a0,800051bc <pipealloc+0xaa>
    800051b6:	a039                	j	800051c4 <pipealloc+0xb2>
    800051b8:	6088                	ld	a0,0(s1)
    800051ba:	c51d                	beqz	a0,800051e8 <pipealloc+0xd6>
    fileclose(*f0);
    800051bc:	00000097          	auipc	ra,0x0
    800051c0:	c26080e7          	jalr	-986(ra) # 80004de2 <fileclose>
  if(*f1)
    800051c4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051c8:	557d                	li	a0,-1
  if(*f1)
    800051ca:	c799                	beqz	a5,800051d8 <pipealloc+0xc6>
    fileclose(*f1);
    800051cc:	853e                	mv	a0,a5
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	c14080e7          	jalr	-1004(ra) # 80004de2 <fileclose>
  return -1;
    800051d6:	557d                	li	a0,-1
}
    800051d8:	70a2                	ld	ra,40(sp)
    800051da:	7402                	ld	s0,32(sp)
    800051dc:	64e2                	ld	s1,24(sp)
    800051de:	6942                	ld	s2,16(sp)
    800051e0:	69a2                	ld	s3,8(sp)
    800051e2:	6a02                	ld	s4,0(sp)
    800051e4:	6145                	addi	sp,sp,48
    800051e6:	8082                	ret
  return -1;
    800051e8:	557d                	li	a0,-1
    800051ea:	b7fd                	j	800051d8 <pipealloc+0xc6>

00000000800051ec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051ec:	1101                	addi	sp,sp,-32
    800051ee:	ec06                	sd	ra,24(sp)
    800051f0:	e822                	sd	s0,16(sp)
    800051f2:	e426                	sd	s1,8(sp)
    800051f4:	e04a                	sd	s2,0(sp)
    800051f6:	1000                	addi	s0,sp,32
    800051f8:	84aa                	mv	s1,a0
    800051fa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	9e8080e7          	jalr	-1560(ra) # 80000be4 <acquire>
  if(writable){
    80005204:	02090d63          	beqz	s2,8000523e <pipeclose+0x52>
    pi->writeopen = 0;
    80005208:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000520c:	21848513          	addi	a0,s1,536
    80005210:	ffffd097          	auipc	ra,0xffffd
    80005214:	e32080e7          	jalr	-462(ra) # 80002042 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005218:	2204b783          	ld	a5,544(s1)
    8000521c:	eb95                	bnez	a5,80005250 <pipeclose+0x64>
    release(&pi->lock);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005228:	8526                	mv	a0,s1
    8000522a:	ffffb097          	auipc	ra,0xffffb
    8000522e:	7ce080e7          	jalr	1998(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005232:	60e2                	ld	ra,24(sp)
    80005234:	6442                	ld	s0,16(sp)
    80005236:	64a2                	ld	s1,8(sp)
    80005238:	6902                	ld	s2,0(sp)
    8000523a:	6105                	addi	sp,sp,32
    8000523c:	8082                	ret
    pi->readopen = 0;
    8000523e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005242:	21c48513          	addi	a0,s1,540
    80005246:	ffffd097          	auipc	ra,0xffffd
    8000524a:	dfc080e7          	jalr	-516(ra) # 80002042 <wakeup>
    8000524e:	b7e9                	j	80005218 <pipeclose+0x2c>
    release(&pi->lock);
    80005250:	8526                	mv	a0,s1
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
}
    8000525a:	bfe1                	j	80005232 <pipeclose+0x46>

000000008000525c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000525c:	7159                	addi	sp,sp,-112
    8000525e:	f486                	sd	ra,104(sp)
    80005260:	f0a2                	sd	s0,96(sp)
    80005262:	eca6                	sd	s1,88(sp)
    80005264:	e8ca                	sd	s2,80(sp)
    80005266:	e4ce                	sd	s3,72(sp)
    80005268:	e0d2                	sd	s4,64(sp)
    8000526a:	fc56                	sd	s5,56(sp)
    8000526c:	f85a                	sd	s6,48(sp)
    8000526e:	f45e                	sd	s7,40(sp)
    80005270:	f062                	sd	s8,32(sp)
    80005272:	ec66                	sd	s9,24(sp)
    80005274:	1880                	addi	s0,sp,112
    80005276:	84aa                	mv	s1,a0
    80005278:	8aae                	mv	s5,a1
    8000527a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	68a080e7          	jalr	1674(ra) # 80001906 <myproc>
    80005284:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005286:	8526                	mv	a0,s1
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	95c080e7          	jalr	-1700(ra) # 80000be4 <acquire>
  while(i < n){
    80005290:	0d405163          	blez	s4,80005352 <pipewrite+0xf6>
    80005294:	8ba6                	mv	s7,s1
  int i = 0;
    80005296:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005298:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000529a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000529e:	21c48c13          	addi	s8,s1,540
    800052a2:	a08d                	j	80005304 <pipewrite+0xa8>
      release(&pi->lock);
    800052a4:	8526                	mv	a0,s1
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
      return -1;
    800052ae:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052b0:	854a                	mv	a0,s2
    800052b2:	70a6                	ld	ra,104(sp)
    800052b4:	7406                	ld	s0,96(sp)
    800052b6:	64e6                	ld	s1,88(sp)
    800052b8:	6946                	ld	s2,80(sp)
    800052ba:	69a6                	ld	s3,72(sp)
    800052bc:	6a06                	ld	s4,64(sp)
    800052be:	7ae2                	ld	s5,56(sp)
    800052c0:	7b42                	ld	s6,48(sp)
    800052c2:	7ba2                	ld	s7,40(sp)
    800052c4:	7c02                	ld	s8,32(sp)
    800052c6:	6ce2                	ld	s9,24(sp)
    800052c8:	6165                	addi	sp,sp,112
    800052ca:	8082                	ret
      wakeup(&pi->nread);
    800052cc:	8566                	mv	a0,s9
    800052ce:	ffffd097          	auipc	ra,0xffffd
    800052d2:	d74080e7          	jalr	-652(ra) # 80002042 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052d6:	85de                	mv	a1,s7
    800052d8:	8562                	mv	a0,s8
    800052da:	ffffd097          	auipc	ra,0xffffd
    800052de:	cee080e7          	jalr	-786(ra) # 80001fc8 <sleep>
    800052e2:	a839                	j	80005300 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052e4:	21c4a783          	lw	a5,540(s1)
    800052e8:	0017871b          	addiw	a4,a5,1
    800052ec:	20e4ae23          	sw	a4,540(s1)
    800052f0:	1ff7f793          	andi	a5,a5,511
    800052f4:	97a6                	add	a5,a5,s1
    800052f6:	f9f44703          	lbu	a4,-97(s0)
    800052fa:	00e78c23          	sb	a4,24(a5)
      i++;
    800052fe:	2905                	addiw	s2,s2,1
  while(i < n){
    80005300:	03495d63          	bge	s2,s4,8000533a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005304:	2204a783          	lw	a5,544(s1)
    80005308:	dfd1                	beqz	a5,800052a4 <pipewrite+0x48>
    8000530a:	0289a783          	lw	a5,40(s3)
    8000530e:	fbd9                	bnez	a5,800052a4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005310:	2184a783          	lw	a5,536(s1)
    80005314:	21c4a703          	lw	a4,540(s1)
    80005318:	2007879b          	addiw	a5,a5,512
    8000531c:	faf708e3          	beq	a4,a5,800052cc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005320:	4685                	li	a3,1
    80005322:	01590633          	add	a2,s2,s5
    80005326:	f9f40593          	addi	a1,s0,-97
    8000532a:	0789b503          	ld	a0,120(s3)
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	3d0080e7          	jalr	976(ra) # 800016fe <copyin>
    80005336:	fb6517e3          	bne	a0,s6,800052e4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000533a:	21848513          	addi	a0,s1,536
    8000533e:	ffffd097          	auipc	ra,0xffffd
    80005342:	d04080e7          	jalr	-764(ra) # 80002042 <wakeup>
  release(&pi->lock);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
  return i;
    80005350:	b785                	j	800052b0 <pipewrite+0x54>
  int i = 0;
    80005352:	4901                	li	s2,0
    80005354:	b7dd                	j	8000533a <pipewrite+0xde>

0000000080005356 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005356:	715d                	addi	sp,sp,-80
    80005358:	e486                	sd	ra,72(sp)
    8000535a:	e0a2                	sd	s0,64(sp)
    8000535c:	fc26                	sd	s1,56(sp)
    8000535e:	f84a                	sd	s2,48(sp)
    80005360:	f44e                	sd	s3,40(sp)
    80005362:	f052                	sd	s4,32(sp)
    80005364:	ec56                	sd	s5,24(sp)
    80005366:	e85a                	sd	s6,16(sp)
    80005368:	0880                	addi	s0,sp,80
    8000536a:	84aa                	mv	s1,a0
    8000536c:	892e                	mv	s2,a1
    8000536e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	596080e7          	jalr	1430(ra) # 80001906 <myproc>
    80005378:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000537a:	8b26                	mv	s6,s1
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005386:	2184a703          	lw	a4,536(s1)
    8000538a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000538e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005392:	02f71463          	bne	a4,a5,800053ba <piperead+0x64>
    80005396:	2244a783          	lw	a5,548(s1)
    8000539a:	c385                	beqz	a5,800053ba <piperead+0x64>
    if(pr->killed){
    8000539c:	028a2783          	lw	a5,40(s4)
    800053a0:	ebc1                	bnez	a5,80005430 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053a2:	85da                	mv	a1,s6
    800053a4:	854e                	mv	a0,s3
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	c22080e7          	jalr	-990(ra) # 80001fc8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053ae:	2184a703          	lw	a4,536(s1)
    800053b2:	21c4a783          	lw	a5,540(s1)
    800053b6:	fef700e3          	beq	a4,a5,80005396 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053ba:	09505263          	blez	s5,8000543e <piperead+0xe8>
    800053be:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053c0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800053c2:	2184a783          	lw	a5,536(s1)
    800053c6:	21c4a703          	lw	a4,540(s1)
    800053ca:	02f70d63          	beq	a4,a5,80005404 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053ce:	0017871b          	addiw	a4,a5,1
    800053d2:	20e4ac23          	sw	a4,536(s1)
    800053d6:	1ff7f793          	andi	a5,a5,511
    800053da:	97a6                	add	a5,a5,s1
    800053dc:	0187c783          	lbu	a5,24(a5)
    800053e0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053e4:	4685                	li	a3,1
    800053e6:	fbf40613          	addi	a2,s0,-65
    800053ea:	85ca                	mv	a1,s2
    800053ec:	078a3503          	ld	a0,120(s4)
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	282080e7          	jalr	642(ra) # 80001672 <copyout>
    800053f8:	01650663          	beq	a0,s6,80005404 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053fc:	2985                	addiw	s3,s3,1
    800053fe:	0905                	addi	s2,s2,1
    80005400:	fd3a91e3          	bne	s5,s3,800053c2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005404:	21c48513          	addi	a0,s1,540
    80005408:	ffffd097          	auipc	ra,0xffffd
    8000540c:	c3a080e7          	jalr	-966(ra) # 80002042 <wakeup>
  release(&pi->lock);
    80005410:	8526                	mv	a0,s1
    80005412:	ffffc097          	auipc	ra,0xffffc
    80005416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
  return i;
}
    8000541a:	854e                	mv	a0,s3
    8000541c:	60a6                	ld	ra,72(sp)
    8000541e:	6406                	ld	s0,64(sp)
    80005420:	74e2                	ld	s1,56(sp)
    80005422:	7942                	ld	s2,48(sp)
    80005424:	79a2                	ld	s3,40(sp)
    80005426:	7a02                	ld	s4,32(sp)
    80005428:	6ae2                	ld	s5,24(sp)
    8000542a:	6b42                	ld	s6,16(sp)
    8000542c:	6161                	addi	sp,sp,80
    8000542e:	8082                	ret
      release(&pi->lock);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
      return -1;
    8000543a:	59fd                	li	s3,-1
    8000543c:	bff9                	j	8000541a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000543e:	4981                	li	s3,0
    80005440:	b7d1                	j	80005404 <piperead+0xae>

0000000080005442 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005442:	df010113          	addi	sp,sp,-528
    80005446:	20113423          	sd	ra,520(sp)
    8000544a:	20813023          	sd	s0,512(sp)
    8000544e:	ffa6                	sd	s1,504(sp)
    80005450:	fbca                	sd	s2,496(sp)
    80005452:	f7ce                	sd	s3,488(sp)
    80005454:	f3d2                	sd	s4,480(sp)
    80005456:	efd6                	sd	s5,472(sp)
    80005458:	ebda                	sd	s6,464(sp)
    8000545a:	e7de                	sd	s7,456(sp)
    8000545c:	e3e2                	sd	s8,448(sp)
    8000545e:	ff66                	sd	s9,440(sp)
    80005460:	fb6a                	sd	s10,432(sp)
    80005462:	f76e                	sd	s11,424(sp)
    80005464:	0c00                	addi	s0,sp,528
    80005466:	84aa                	mv	s1,a0
    80005468:	dea43c23          	sd	a0,-520(s0)
    8000546c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005470:	ffffc097          	auipc	ra,0xffffc
    80005474:	496080e7          	jalr	1174(ra) # 80001906 <myproc>
    80005478:	892a                	mv	s2,a0

  begin_op();
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	49c080e7          	jalr	1180(ra) # 80004916 <begin_op>

  if((ip = namei(path)) == 0){
    80005482:	8526                	mv	a0,s1
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	276080e7          	jalr	630(ra) # 800046fa <namei>
    8000548c:	c92d                	beqz	a0,800054fe <exec+0xbc>
    8000548e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	ab4080e7          	jalr	-1356(ra) # 80003f44 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005498:	04000713          	li	a4,64
    8000549c:	4681                	li	a3,0
    8000549e:	e5040613          	addi	a2,s0,-432
    800054a2:	4581                	li	a1,0
    800054a4:	8526                	mv	a0,s1
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	d52080e7          	jalr	-686(ra) # 800041f8 <readi>
    800054ae:	04000793          	li	a5,64
    800054b2:	00f51a63          	bne	a0,a5,800054c6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800054b6:	e5042703          	lw	a4,-432(s0)
    800054ba:	464c47b7          	lui	a5,0x464c4
    800054be:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054c2:	04f70463          	beq	a4,a5,8000550a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	cde080e7          	jalr	-802(ra) # 800041a6 <iunlockput>
    end_op();
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	4c6080e7          	jalr	1222(ra) # 80004996 <end_op>
  }
  return -1;
    800054d8:	557d                	li	a0,-1
}
    800054da:	20813083          	ld	ra,520(sp)
    800054de:	20013403          	ld	s0,512(sp)
    800054e2:	74fe                	ld	s1,504(sp)
    800054e4:	795e                	ld	s2,496(sp)
    800054e6:	79be                	ld	s3,488(sp)
    800054e8:	7a1e                	ld	s4,480(sp)
    800054ea:	6afe                	ld	s5,472(sp)
    800054ec:	6b5e                	ld	s6,464(sp)
    800054ee:	6bbe                	ld	s7,456(sp)
    800054f0:	6c1e                	ld	s8,448(sp)
    800054f2:	7cfa                	ld	s9,440(sp)
    800054f4:	7d5a                	ld	s10,432(sp)
    800054f6:	7dba                	ld	s11,424(sp)
    800054f8:	21010113          	addi	sp,sp,528
    800054fc:	8082                	ret
    end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	498080e7          	jalr	1176(ra) # 80004996 <end_op>
    return -1;
    80005506:	557d                	li	a0,-1
    80005508:	bfc9                	j	800054da <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000550a:	854a                	mv	a0,s2
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	4b6080e7          	jalr	1206(ra) # 800019c2 <proc_pagetable>
    80005514:	8baa                	mv	s7,a0
    80005516:	d945                	beqz	a0,800054c6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005518:	e7042983          	lw	s3,-400(s0)
    8000551c:	e8845783          	lhu	a5,-376(s0)
    80005520:	c7ad                	beqz	a5,8000558a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005522:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005524:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005526:	6c85                	lui	s9,0x1
    80005528:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000552c:	def43823          	sd	a5,-528(s0)
    80005530:	a42d                	j	8000575a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005532:	00003517          	auipc	a0,0x3
    80005536:	1ce50513          	addi	a0,a0,462 # 80008700 <syscalls+0x298>
    8000553a:	ffffb097          	auipc	ra,0xffffb
    8000553e:	004080e7          	jalr	4(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005542:	8756                	mv	a4,s5
    80005544:	012d86bb          	addw	a3,s11,s2
    80005548:	4581                	li	a1,0
    8000554a:	8526                	mv	a0,s1
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	cac080e7          	jalr	-852(ra) # 800041f8 <readi>
    80005554:	2501                	sext.w	a0,a0
    80005556:	1aaa9963          	bne	s5,a0,80005708 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000555a:	6785                	lui	a5,0x1
    8000555c:	0127893b          	addw	s2,a5,s2
    80005560:	77fd                	lui	a5,0xfffff
    80005562:	01478a3b          	addw	s4,a5,s4
    80005566:	1f897163          	bgeu	s2,s8,80005748 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000556a:	02091593          	slli	a1,s2,0x20
    8000556e:	9181                	srli	a1,a1,0x20
    80005570:	95ea                	add	a1,a1,s10
    80005572:	855e                	mv	a0,s7
    80005574:	ffffc097          	auipc	ra,0xffffc
    80005578:	afa080e7          	jalr	-1286(ra) # 8000106e <walkaddr>
    8000557c:	862a                	mv	a2,a0
    if(pa == 0)
    8000557e:	d955                	beqz	a0,80005532 <exec+0xf0>
      n = PGSIZE;
    80005580:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005582:	fd9a70e3          	bgeu	s4,s9,80005542 <exec+0x100>
      n = sz - i;
    80005586:	8ad2                	mv	s5,s4
    80005588:	bf6d                	j	80005542 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000558a:	4901                	li	s2,0
  iunlockput(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	c18080e7          	jalr	-1000(ra) # 800041a6 <iunlockput>
  end_op();
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	400080e7          	jalr	1024(ra) # 80004996 <end_op>
  p = myproc();
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	368080e7          	jalr	872(ra) # 80001906 <myproc>
    800055a6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800055a8:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    800055ac:	6785                	lui	a5,0x1
    800055ae:	17fd                	addi	a5,a5,-1
    800055b0:	993e                	add	s2,s2,a5
    800055b2:	757d                	lui	a0,0xfffff
    800055b4:	00a977b3          	and	a5,s2,a0
    800055b8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055bc:	6609                	lui	a2,0x2
    800055be:	963e                	add	a2,a2,a5
    800055c0:	85be                	mv	a1,a5
    800055c2:	855e                	mv	a0,s7
    800055c4:	ffffc097          	auipc	ra,0xffffc
    800055c8:	e5e080e7          	jalr	-418(ra) # 80001422 <uvmalloc>
    800055cc:	8b2a                	mv	s6,a0
  ip = 0;
    800055ce:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055d0:	12050c63          	beqz	a0,80005708 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055d4:	75f9                	lui	a1,0xffffe
    800055d6:	95aa                	add	a1,a1,a0
    800055d8:	855e                	mv	a0,s7
    800055da:	ffffc097          	auipc	ra,0xffffc
    800055de:	066080e7          	jalr	102(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800055e2:	7c7d                	lui	s8,0xfffff
    800055e4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800055e6:	e0043783          	ld	a5,-512(s0)
    800055ea:	6388                	ld	a0,0(a5)
    800055ec:	c535                	beqz	a0,80005658 <exec+0x216>
    800055ee:	e9040993          	addi	s3,s0,-368
    800055f2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800055f6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800055f8:	ffffc097          	auipc	ra,0xffffc
    800055fc:	86c080e7          	jalr	-1940(ra) # 80000e64 <strlen>
    80005600:	2505                	addiw	a0,a0,1
    80005602:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005606:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000560a:	13896363          	bltu	s2,s8,80005730 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000560e:	e0043d83          	ld	s11,-512(s0)
    80005612:	000dba03          	ld	s4,0(s11)
    80005616:	8552                	mv	a0,s4
    80005618:	ffffc097          	auipc	ra,0xffffc
    8000561c:	84c080e7          	jalr	-1972(ra) # 80000e64 <strlen>
    80005620:	0015069b          	addiw	a3,a0,1
    80005624:	8652                	mv	a2,s4
    80005626:	85ca                	mv	a1,s2
    80005628:	855e                	mv	a0,s7
    8000562a:	ffffc097          	auipc	ra,0xffffc
    8000562e:	048080e7          	jalr	72(ra) # 80001672 <copyout>
    80005632:	10054363          	bltz	a0,80005738 <exec+0x2f6>
    ustack[argc] = sp;
    80005636:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000563a:	0485                	addi	s1,s1,1
    8000563c:	008d8793          	addi	a5,s11,8
    80005640:	e0f43023          	sd	a5,-512(s0)
    80005644:	008db503          	ld	a0,8(s11)
    80005648:	c911                	beqz	a0,8000565c <exec+0x21a>
    if(argc >= MAXARG)
    8000564a:	09a1                	addi	s3,s3,8
    8000564c:	fb3c96e3          	bne	s9,s3,800055f8 <exec+0x1b6>
  sz = sz1;
    80005650:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005654:	4481                	li	s1,0
    80005656:	a84d                	j	80005708 <exec+0x2c6>
  sp = sz;
    80005658:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000565a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000565c:	00349793          	slli	a5,s1,0x3
    80005660:	f9040713          	addi	a4,s0,-112
    80005664:	97ba                	add	a5,a5,a4
    80005666:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000566a:	00148693          	addi	a3,s1,1
    8000566e:	068e                	slli	a3,a3,0x3
    80005670:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005674:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005678:	01897663          	bgeu	s2,s8,80005684 <exec+0x242>
  sz = sz1;
    8000567c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005680:	4481                	li	s1,0
    80005682:	a059                	j	80005708 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005684:	e9040613          	addi	a2,s0,-368
    80005688:	85ca                	mv	a1,s2
    8000568a:	855e                	mv	a0,s7
    8000568c:	ffffc097          	auipc	ra,0xffffc
    80005690:	fe6080e7          	jalr	-26(ra) # 80001672 <copyout>
    80005694:	0a054663          	bltz	a0,80005740 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005698:	080ab783          	ld	a5,128(s5)
    8000569c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800056a0:	df843783          	ld	a5,-520(s0)
    800056a4:	0007c703          	lbu	a4,0(a5)
    800056a8:	cf11                	beqz	a4,800056c4 <exec+0x282>
    800056aa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800056ac:	02f00693          	li	a3,47
    800056b0:	a039                	j	800056be <exec+0x27c>
      last = s+1;
    800056b2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800056b6:	0785                	addi	a5,a5,1
    800056b8:	fff7c703          	lbu	a4,-1(a5)
    800056bc:	c701                	beqz	a4,800056c4 <exec+0x282>
    if(*s == '/')
    800056be:	fed71ce3          	bne	a4,a3,800056b6 <exec+0x274>
    800056c2:	bfc5                	j	800056b2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800056c4:	4641                	li	a2,16
    800056c6:	df843583          	ld	a1,-520(s0)
    800056ca:	180a8513          	addi	a0,s5,384
    800056ce:	ffffb097          	auipc	ra,0xffffb
    800056d2:	764080e7          	jalr	1892(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800056d6:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    800056da:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    800056de:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056e2:	080ab783          	ld	a5,128(s5)
    800056e6:	e6843703          	ld	a4,-408(s0)
    800056ea:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056ec:	080ab783          	ld	a5,128(s5)
    800056f0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056f4:	85ea                	mv	a1,s10
    800056f6:	ffffc097          	auipc	ra,0xffffc
    800056fa:	368080e7          	jalr	872(ra) # 80001a5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056fe:	0004851b          	sext.w	a0,s1
    80005702:	bbe1                	j	800054da <exec+0x98>
    80005704:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005708:	e0843583          	ld	a1,-504(s0)
    8000570c:	855e                	mv	a0,s7
    8000570e:	ffffc097          	auipc	ra,0xffffc
    80005712:	350080e7          	jalr	848(ra) # 80001a5e <proc_freepagetable>
  if(ip){
    80005716:	da0498e3          	bnez	s1,800054c6 <exec+0x84>
  return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	bb7d                	j	800054da <exec+0x98>
    8000571e:	e1243423          	sd	s2,-504(s0)
    80005722:	b7dd                	j	80005708 <exec+0x2c6>
    80005724:	e1243423          	sd	s2,-504(s0)
    80005728:	b7c5                	j	80005708 <exec+0x2c6>
    8000572a:	e1243423          	sd	s2,-504(s0)
    8000572e:	bfe9                	j	80005708 <exec+0x2c6>
  sz = sz1;
    80005730:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005734:	4481                	li	s1,0
    80005736:	bfc9                	j	80005708 <exec+0x2c6>
  sz = sz1;
    80005738:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000573c:	4481                	li	s1,0
    8000573e:	b7e9                	j	80005708 <exec+0x2c6>
  sz = sz1;
    80005740:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005744:	4481                	li	s1,0
    80005746:	b7c9                	j	80005708 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005748:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000574c:	2b05                	addiw	s6,s6,1
    8000574e:	0389899b          	addiw	s3,s3,56
    80005752:	e8845783          	lhu	a5,-376(s0)
    80005756:	e2fb5be3          	bge	s6,a5,8000558c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000575a:	2981                	sext.w	s3,s3
    8000575c:	03800713          	li	a4,56
    80005760:	86ce                	mv	a3,s3
    80005762:	e1840613          	addi	a2,s0,-488
    80005766:	4581                	li	a1,0
    80005768:	8526                	mv	a0,s1
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	a8e080e7          	jalr	-1394(ra) # 800041f8 <readi>
    80005772:	03800793          	li	a5,56
    80005776:	f8f517e3          	bne	a0,a5,80005704 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000577a:	e1842783          	lw	a5,-488(s0)
    8000577e:	4705                	li	a4,1
    80005780:	fce796e3          	bne	a5,a4,8000574c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005784:	e4043603          	ld	a2,-448(s0)
    80005788:	e3843783          	ld	a5,-456(s0)
    8000578c:	f8f669e3          	bltu	a2,a5,8000571e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005790:	e2843783          	ld	a5,-472(s0)
    80005794:	963e                	add	a2,a2,a5
    80005796:	f8f667e3          	bltu	a2,a5,80005724 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000579a:	85ca                	mv	a1,s2
    8000579c:	855e                	mv	a0,s7
    8000579e:	ffffc097          	auipc	ra,0xffffc
    800057a2:	c84080e7          	jalr	-892(ra) # 80001422 <uvmalloc>
    800057a6:	e0a43423          	sd	a0,-504(s0)
    800057aa:	d141                	beqz	a0,8000572a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800057ac:	e2843d03          	ld	s10,-472(s0)
    800057b0:	df043783          	ld	a5,-528(s0)
    800057b4:	00fd77b3          	and	a5,s10,a5
    800057b8:	fba1                	bnez	a5,80005708 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057ba:	e2042d83          	lw	s11,-480(s0)
    800057be:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057c2:	f80c03e3          	beqz	s8,80005748 <exec+0x306>
    800057c6:	8a62                	mv	s4,s8
    800057c8:	4901                	li	s2,0
    800057ca:	b345                	j	8000556a <exec+0x128>

00000000800057cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057cc:	7179                	addi	sp,sp,-48
    800057ce:	f406                	sd	ra,40(sp)
    800057d0:	f022                	sd	s0,32(sp)
    800057d2:	ec26                	sd	s1,24(sp)
    800057d4:	e84a                	sd	s2,16(sp)
    800057d6:	1800                	addi	s0,sp,48
    800057d8:	892e                	mv	s2,a1
    800057da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800057dc:	fdc40593          	addi	a1,s0,-36
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	b76080e7          	jalr	-1162(ra) # 80003356 <argint>
    800057e8:	04054063          	bltz	a0,80005828 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057ec:	fdc42703          	lw	a4,-36(s0)
    800057f0:	47bd                	li	a5,15
    800057f2:	02e7ed63          	bltu	a5,a4,8000582c <argfd+0x60>
    800057f6:	ffffc097          	auipc	ra,0xffffc
    800057fa:	110080e7          	jalr	272(ra) # 80001906 <myproc>
    800057fe:	fdc42703          	lw	a4,-36(s0)
    80005802:	01e70793          	addi	a5,a4,30
    80005806:	078e                	slli	a5,a5,0x3
    80005808:	953e                	add	a0,a0,a5
    8000580a:	651c                	ld	a5,8(a0)
    8000580c:	c395                	beqz	a5,80005830 <argfd+0x64>
    return -1;
  if(pfd)
    8000580e:	00090463          	beqz	s2,80005816 <argfd+0x4a>
    *pfd = fd;
    80005812:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005816:	4501                	li	a0,0
  if(pf)
    80005818:	c091                	beqz	s1,8000581c <argfd+0x50>
    *pf = f;
    8000581a:	e09c                	sd	a5,0(s1)
}
    8000581c:	70a2                	ld	ra,40(sp)
    8000581e:	7402                	ld	s0,32(sp)
    80005820:	64e2                	ld	s1,24(sp)
    80005822:	6942                	ld	s2,16(sp)
    80005824:	6145                	addi	sp,sp,48
    80005826:	8082                	ret
    return -1;
    80005828:	557d                	li	a0,-1
    8000582a:	bfcd                	j	8000581c <argfd+0x50>
    return -1;
    8000582c:	557d                	li	a0,-1
    8000582e:	b7fd                	j	8000581c <argfd+0x50>
    80005830:	557d                	li	a0,-1
    80005832:	b7ed                	j	8000581c <argfd+0x50>

0000000080005834 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005834:	1101                	addi	sp,sp,-32
    80005836:	ec06                	sd	ra,24(sp)
    80005838:	e822                	sd	s0,16(sp)
    8000583a:	e426                	sd	s1,8(sp)
    8000583c:	1000                	addi	s0,sp,32
    8000583e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005840:	ffffc097          	auipc	ra,0xffffc
    80005844:	0c6080e7          	jalr	198(ra) # 80001906 <myproc>
    80005848:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000584a:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd80f8>
    8000584e:	4501                	li	a0,0
    80005850:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005852:	6398                	ld	a4,0(a5)
    80005854:	cb19                	beqz	a4,8000586a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005856:	2505                	addiw	a0,a0,1
    80005858:	07a1                	addi	a5,a5,8
    8000585a:	fed51ce3          	bne	a0,a3,80005852 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000585e:	557d                	li	a0,-1
}
    80005860:	60e2                	ld	ra,24(sp)
    80005862:	6442                	ld	s0,16(sp)
    80005864:	64a2                	ld	s1,8(sp)
    80005866:	6105                	addi	sp,sp,32
    80005868:	8082                	ret
      p->ofile[fd] = f;
    8000586a:	01e50793          	addi	a5,a0,30
    8000586e:	078e                	slli	a5,a5,0x3
    80005870:	963e                	add	a2,a2,a5
    80005872:	e604                	sd	s1,8(a2)
      return fd;
    80005874:	b7f5                	j	80005860 <fdalloc+0x2c>

0000000080005876 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005876:	715d                	addi	sp,sp,-80
    80005878:	e486                	sd	ra,72(sp)
    8000587a:	e0a2                	sd	s0,64(sp)
    8000587c:	fc26                	sd	s1,56(sp)
    8000587e:	f84a                	sd	s2,48(sp)
    80005880:	f44e                	sd	s3,40(sp)
    80005882:	f052                	sd	s4,32(sp)
    80005884:	ec56                	sd	s5,24(sp)
    80005886:	0880                	addi	s0,sp,80
    80005888:	89ae                	mv	s3,a1
    8000588a:	8ab2                	mv	s5,a2
    8000588c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000588e:	fb040593          	addi	a1,s0,-80
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	e86080e7          	jalr	-378(ra) # 80004718 <nameiparent>
    8000589a:	892a                	mv	s2,a0
    8000589c:	12050f63          	beqz	a0,800059da <create+0x164>
    return 0;

  ilock(dp);
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	6a4080e7          	jalr	1700(ra) # 80003f44 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800058a8:	4601                	li	a2,0
    800058aa:	fb040593          	addi	a1,s0,-80
    800058ae:	854a                	mv	a0,s2
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	b78080e7          	jalr	-1160(ra) # 80004428 <dirlookup>
    800058b8:	84aa                	mv	s1,a0
    800058ba:	c921                	beqz	a0,8000590a <create+0x94>
    iunlockput(dp);
    800058bc:	854a                	mv	a0,s2
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	8e8080e7          	jalr	-1816(ra) # 800041a6 <iunlockput>
    ilock(ip);
    800058c6:	8526                	mv	a0,s1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	67c080e7          	jalr	1660(ra) # 80003f44 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058d0:	2981                	sext.w	s3,s3
    800058d2:	4789                	li	a5,2
    800058d4:	02f99463          	bne	s3,a5,800058fc <create+0x86>
    800058d8:	0444d783          	lhu	a5,68(s1)
    800058dc:	37f9                	addiw	a5,a5,-2
    800058de:	17c2                	slli	a5,a5,0x30
    800058e0:	93c1                	srli	a5,a5,0x30
    800058e2:	4705                	li	a4,1
    800058e4:	00f76c63          	bltu	a4,a5,800058fc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800058e8:	8526                	mv	a0,s1
    800058ea:	60a6                	ld	ra,72(sp)
    800058ec:	6406                	ld	s0,64(sp)
    800058ee:	74e2                	ld	s1,56(sp)
    800058f0:	7942                	ld	s2,48(sp)
    800058f2:	79a2                	ld	s3,40(sp)
    800058f4:	7a02                	ld	s4,32(sp)
    800058f6:	6ae2                	ld	s5,24(sp)
    800058f8:	6161                	addi	sp,sp,80
    800058fa:	8082                	ret
    iunlockput(ip);
    800058fc:	8526                	mv	a0,s1
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	8a8080e7          	jalr	-1880(ra) # 800041a6 <iunlockput>
    return 0;
    80005906:	4481                	li	s1,0
    80005908:	b7c5                	j	800058e8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000590a:	85ce                	mv	a1,s3
    8000590c:	00092503          	lw	a0,0(s2)
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	49c080e7          	jalr	1180(ra) # 80003dac <ialloc>
    80005918:	84aa                	mv	s1,a0
    8000591a:	c529                	beqz	a0,80005964 <create+0xee>
  ilock(ip);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	628080e7          	jalr	1576(ra) # 80003f44 <ilock>
  ip->major = major;
    80005924:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005928:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000592c:	4785                	li	a5,1
    8000592e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	546080e7          	jalr	1350(ra) # 80003e7a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000593c:	2981                	sext.w	s3,s3
    8000593e:	4785                	li	a5,1
    80005940:	02f98a63          	beq	s3,a5,80005974 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005944:	40d0                	lw	a2,4(s1)
    80005946:	fb040593          	addi	a1,s0,-80
    8000594a:	854a                	mv	a0,s2
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	cec080e7          	jalr	-788(ra) # 80004638 <dirlink>
    80005954:	06054b63          	bltz	a0,800059ca <create+0x154>
  iunlockput(dp);
    80005958:	854a                	mv	a0,s2
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	84c080e7          	jalr	-1972(ra) # 800041a6 <iunlockput>
  return ip;
    80005962:	b759                	j	800058e8 <create+0x72>
    panic("create: ialloc");
    80005964:	00003517          	auipc	a0,0x3
    80005968:	dbc50513          	addi	a0,a0,-580 # 80008720 <syscalls+0x2b8>
    8000596c:	ffffb097          	auipc	ra,0xffffb
    80005970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005974:	04a95783          	lhu	a5,74(s2)
    80005978:	2785                	addiw	a5,a5,1
    8000597a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000597e:	854a                	mv	a0,s2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	4fa080e7          	jalr	1274(ra) # 80003e7a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005988:	40d0                	lw	a2,4(s1)
    8000598a:	00003597          	auipc	a1,0x3
    8000598e:	da658593          	addi	a1,a1,-602 # 80008730 <syscalls+0x2c8>
    80005992:	8526                	mv	a0,s1
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	ca4080e7          	jalr	-860(ra) # 80004638 <dirlink>
    8000599c:	00054f63          	bltz	a0,800059ba <create+0x144>
    800059a0:	00492603          	lw	a2,4(s2)
    800059a4:	00003597          	auipc	a1,0x3
    800059a8:	d9458593          	addi	a1,a1,-620 # 80008738 <syscalls+0x2d0>
    800059ac:	8526                	mv	a0,s1
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	c8a080e7          	jalr	-886(ra) # 80004638 <dirlink>
    800059b6:	f80557e3          	bgez	a0,80005944 <create+0xce>
      panic("create dots");
    800059ba:	00003517          	auipc	a0,0x3
    800059be:	d8650513          	addi	a0,a0,-634 # 80008740 <syscalls+0x2d8>
    800059c2:	ffffb097          	auipc	ra,0xffffb
    800059c6:	b7c080e7          	jalr	-1156(ra) # 8000053e <panic>
    panic("create: dirlink");
    800059ca:	00003517          	auipc	a0,0x3
    800059ce:	d8650513          	addi	a0,a0,-634 # 80008750 <syscalls+0x2e8>
    800059d2:	ffffb097          	auipc	ra,0xffffb
    800059d6:	b6c080e7          	jalr	-1172(ra) # 8000053e <panic>
    return 0;
    800059da:	84aa                	mv	s1,a0
    800059dc:	b731                	j	800058e8 <create+0x72>

00000000800059de <sys_dup>:
{
    800059de:	7179                	addi	sp,sp,-48
    800059e0:	f406                	sd	ra,40(sp)
    800059e2:	f022                	sd	s0,32(sp)
    800059e4:	ec26                	sd	s1,24(sp)
    800059e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059e8:	fd840613          	addi	a2,s0,-40
    800059ec:	4581                	li	a1,0
    800059ee:	4501                	li	a0,0
    800059f0:	00000097          	auipc	ra,0x0
    800059f4:	ddc080e7          	jalr	-548(ra) # 800057cc <argfd>
    return -1;
    800059f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059fa:	02054363          	bltz	a0,80005a20 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059fe:	fd843503          	ld	a0,-40(s0)
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	e32080e7          	jalr	-462(ra) # 80005834 <fdalloc>
    80005a0a:	84aa                	mv	s1,a0
    return -1;
    80005a0c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a0e:	00054963          	bltz	a0,80005a20 <sys_dup+0x42>
  filedup(f);
    80005a12:	fd843503          	ld	a0,-40(s0)
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	37a080e7          	jalr	890(ra) # 80004d90 <filedup>
  return fd;
    80005a1e:	87a6                	mv	a5,s1
}
    80005a20:	853e                	mv	a0,a5
    80005a22:	70a2                	ld	ra,40(sp)
    80005a24:	7402                	ld	s0,32(sp)
    80005a26:	64e2                	ld	s1,24(sp)
    80005a28:	6145                	addi	sp,sp,48
    80005a2a:	8082                	ret

0000000080005a2c <sys_read>:
{
    80005a2c:	7179                	addi	sp,sp,-48
    80005a2e:	f406                	sd	ra,40(sp)
    80005a30:	f022                	sd	s0,32(sp)
    80005a32:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a34:	fe840613          	addi	a2,s0,-24
    80005a38:	4581                	li	a1,0
    80005a3a:	4501                	li	a0,0
    80005a3c:	00000097          	auipc	ra,0x0
    80005a40:	d90080e7          	jalr	-624(ra) # 800057cc <argfd>
    return -1;
    80005a44:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a46:	04054163          	bltz	a0,80005a88 <sys_read+0x5c>
    80005a4a:	fe440593          	addi	a1,s0,-28
    80005a4e:	4509                	li	a0,2
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	906080e7          	jalr	-1786(ra) # 80003356 <argint>
    return -1;
    80005a58:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a5a:	02054763          	bltz	a0,80005a88 <sys_read+0x5c>
    80005a5e:	fd840593          	addi	a1,s0,-40
    80005a62:	4505                	li	a0,1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	914080e7          	jalr	-1772(ra) # 80003378 <argaddr>
    return -1;
    80005a6c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a6e:	00054d63          	bltz	a0,80005a88 <sys_read+0x5c>
  return fileread(f, p, n);
    80005a72:	fe442603          	lw	a2,-28(s0)
    80005a76:	fd843583          	ld	a1,-40(s0)
    80005a7a:	fe843503          	ld	a0,-24(s0)
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	49e080e7          	jalr	1182(ra) # 80004f1c <fileread>
    80005a86:	87aa                	mv	a5,a0
}
    80005a88:	853e                	mv	a0,a5
    80005a8a:	70a2                	ld	ra,40(sp)
    80005a8c:	7402                	ld	s0,32(sp)
    80005a8e:	6145                	addi	sp,sp,48
    80005a90:	8082                	ret

0000000080005a92 <sys_write>:
{
    80005a92:	7179                	addi	sp,sp,-48
    80005a94:	f406                	sd	ra,40(sp)
    80005a96:	f022                	sd	s0,32(sp)
    80005a98:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a9a:	fe840613          	addi	a2,s0,-24
    80005a9e:	4581                	li	a1,0
    80005aa0:	4501                	li	a0,0
    80005aa2:	00000097          	auipc	ra,0x0
    80005aa6:	d2a080e7          	jalr	-726(ra) # 800057cc <argfd>
    return -1;
    80005aaa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aac:	04054163          	bltz	a0,80005aee <sys_write+0x5c>
    80005ab0:	fe440593          	addi	a1,s0,-28
    80005ab4:	4509                	li	a0,2
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	8a0080e7          	jalr	-1888(ra) # 80003356 <argint>
    return -1;
    80005abe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ac0:	02054763          	bltz	a0,80005aee <sys_write+0x5c>
    80005ac4:	fd840593          	addi	a1,s0,-40
    80005ac8:	4505                	li	a0,1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	8ae080e7          	jalr	-1874(ra) # 80003378 <argaddr>
    return -1;
    80005ad2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ad4:	00054d63          	bltz	a0,80005aee <sys_write+0x5c>
  return filewrite(f, p, n);
    80005ad8:	fe442603          	lw	a2,-28(s0)
    80005adc:	fd843583          	ld	a1,-40(s0)
    80005ae0:	fe843503          	ld	a0,-24(s0)
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	4fa080e7          	jalr	1274(ra) # 80004fde <filewrite>
    80005aec:	87aa                	mv	a5,a0
}
    80005aee:	853e                	mv	a0,a5
    80005af0:	70a2                	ld	ra,40(sp)
    80005af2:	7402                	ld	s0,32(sp)
    80005af4:	6145                	addi	sp,sp,48
    80005af6:	8082                	ret

0000000080005af8 <sys_close>:
{
    80005af8:	1101                	addi	sp,sp,-32
    80005afa:	ec06                	sd	ra,24(sp)
    80005afc:	e822                	sd	s0,16(sp)
    80005afe:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b00:	fe040613          	addi	a2,s0,-32
    80005b04:	fec40593          	addi	a1,s0,-20
    80005b08:	4501                	li	a0,0
    80005b0a:	00000097          	auipc	ra,0x0
    80005b0e:	cc2080e7          	jalr	-830(ra) # 800057cc <argfd>
    return -1;
    80005b12:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b14:	02054463          	bltz	a0,80005b3c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b18:	ffffc097          	auipc	ra,0xffffc
    80005b1c:	dee080e7          	jalr	-530(ra) # 80001906 <myproc>
    80005b20:	fec42783          	lw	a5,-20(s0)
    80005b24:	07f9                	addi	a5,a5,30
    80005b26:	078e                	slli	a5,a5,0x3
    80005b28:	97aa                	add	a5,a5,a0
    80005b2a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005b2e:	fe043503          	ld	a0,-32(s0)
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	2b0080e7          	jalr	688(ra) # 80004de2 <fileclose>
  return 0;
    80005b3a:	4781                	li	a5,0
}
    80005b3c:	853e                	mv	a0,a5
    80005b3e:	60e2                	ld	ra,24(sp)
    80005b40:	6442                	ld	s0,16(sp)
    80005b42:	6105                	addi	sp,sp,32
    80005b44:	8082                	ret

0000000080005b46 <sys_fstat>:
{
    80005b46:	1101                	addi	sp,sp,-32
    80005b48:	ec06                	sd	ra,24(sp)
    80005b4a:	e822                	sd	s0,16(sp)
    80005b4c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b4e:	fe840613          	addi	a2,s0,-24
    80005b52:	4581                	li	a1,0
    80005b54:	4501                	li	a0,0
    80005b56:	00000097          	auipc	ra,0x0
    80005b5a:	c76080e7          	jalr	-906(ra) # 800057cc <argfd>
    return -1;
    80005b5e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b60:	02054563          	bltz	a0,80005b8a <sys_fstat+0x44>
    80005b64:	fe040593          	addi	a1,s0,-32
    80005b68:	4505                	li	a0,1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	80e080e7          	jalr	-2034(ra) # 80003378 <argaddr>
    return -1;
    80005b72:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b74:	00054b63          	bltz	a0,80005b8a <sys_fstat+0x44>
  return filestat(f, st);
    80005b78:	fe043583          	ld	a1,-32(s0)
    80005b7c:	fe843503          	ld	a0,-24(s0)
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	32a080e7          	jalr	810(ra) # 80004eaa <filestat>
    80005b88:	87aa                	mv	a5,a0
}
    80005b8a:	853e                	mv	a0,a5
    80005b8c:	60e2                	ld	ra,24(sp)
    80005b8e:	6442                	ld	s0,16(sp)
    80005b90:	6105                	addi	sp,sp,32
    80005b92:	8082                	ret

0000000080005b94 <sys_link>:
{
    80005b94:	7169                	addi	sp,sp,-304
    80005b96:	f606                	sd	ra,296(sp)
    80005b98:	f222                	sd	s0,288(sp)
    80005b9a:	ee26                	sd	s1,280(sp)
    80005b9c:	ea4a                	sd	s2,272(sp)
    80005b9e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ba0:	08000613          	li	a2,128
    80005ba4:	ed040593          	addi	a1,s0,-304
    80005ba8:	4501                	li	a0,0
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	7f0080e7          	jalr	2032(ra) # 8000339a <argstr>
    return -1;
    80005bb2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bb4:	10054e63          	bltz	a0,80005cd0 <sys_link+0x13c>
    80005bb8:	08000613          	li	a2,128
    80005bbc:	f5040593          	addi	a1,s0,-176
    80005bc0:	4505                	li	a0,1
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	7d8080e7          	jalr	2008(ra) # 8000339a <argstr>
    return -1;
    80005bca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bcc:	10054263          	bltz	a0,80005cd0 <sys_link+0x13c>
  begin_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	d46080e7          	jalr	-698(ra) # 80004916 <begin_op>
  if((ip = namei(old)) == 0){
    80005bd8:	ed040513          	addi	a0,s0,-304
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	b1e080e7          	jalr	-1250(ra) # 800046fa <namei>
    80005be4:	84aa                	mv	s1,a0
    80005be6:	c551                	beqz	a0,80005c72 <sys_link+0xde>
  ilock(ip);
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	35c080e7          	jalr	860(ra) # 80003f44 <ilock>
  if(ip->type == T_DIR){
    80005bf0:	04449703          	lh	a4,68(s1)
    80005bf4:	4785                	li	a5,1
    80005bf6:	08f70463          	beq	a4,a5,80005c7e <sys_link+0xea>
  ip->nlink++;
    80005bfa:	04a4d783          	lhu	a5,74(s1)
    80005bfe:	2785                	addiw	a5,a5,1
    80005c00:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c04:	8526                	mv	a0,s1
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	274080e7          	jalr	628(ra) # 80003e7a <iupdate>
  iunlock(ip);
    80005c0e:	8526                	mv	a0,s1
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	3f6080e7          	jalr	1014(ra) # 80004006 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c18:	fd040593          	addi	a1,s0,-48
    80005c1c:	f5040513          	addi	a0,s0,-176
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	af8080e7          	jalr	-1288(ra) # 80004718 <nameiparent>
    80005c28:	892a                	mv	s2,a0
    80005c2a:	c935                	beqz	a0,80005c9e <sys_link+0x10a>
  ilock(dp);
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	318080e7          	jalr	792(ra) # 80003f44 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c34:	00092703          	lw	a4,0(s2)
    80005c38:	409c                	lw	a5,0(s1)
    80005c3a:	04f71d63          	bne	a4,a5,80005c94 <sys_link+0x100>
    80005c3e:	40d0                	lw	a2,4(s1)
    80005c40:	fd040593          	addi	a1,s0,-48
    80005c44:	854a                	mv	a0,s2
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	9f2080e7          	jalr	-1550(ra) # 80004638 <dirlink>
    80005c4e:	04054363          	bltz	a0,80005c94 <sys_link+0x100>
  iunlockput(dp);
    80005c52:	854a                	mv	a0,s2
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	552080e7          	jalr	1362(ra) # 800041a6 <iunlockput>
  iput(ip);
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	4a0080e7          	jalr	1184(ra) # 800040fe <iput>
  end_op();
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	d30080e7          	jalr	-720(ra) # 80004996 <end_op>
  return 0;
    80005c6e:	4781                	li	a5,0
    80005c70:	a085                	j	80005cd0 <sys_link+0x13c>
    end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	d24080e7          	jalr	-732(ra) # 80004996 <end_op>
    return -1;
    80005c7a:	57fd                	li	a5,-1
    80005c7c:	a891                	j	80005cd0 <sys_link+0x13c>
    iunlockput(ip);
    80005c7e:	8526                	mv	a0,s1
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	526080e7          	jalr	1318(ra) # 800041a6 <iunlockput>
    end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	d0e080e7          	jalr	-754(ra) # 80004996 <end_op>
    return -1;
    80005c90:	57fd                	li	a5,-1
    80005c92:	a83d                	j	80005cd0 <sys_link+0x13c>
    iunlockput(dp);
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	510080e7          	jalr	1296(ra) # 800041a6 <iunlockput>
  ilock(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	2a4080e7          	jalr	676(ra) # 80003f44 <ilock>
  ip->nlink--;
    80005ca8:	04a4d783          	lhu	a5,74(s1)
    80005cac:	37fd                	addiw	a5,a5,-1
    80005cae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cb2:	8526                	mv	a0,s1
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	1c6080e7          	jalr	454(ra) # 80003e7a <iupdate>
  iunlockput(ip);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	4e8080e7          	jalr	1256(ra) # 800041a6 <iunlockput>
  end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	cd0080e7          	jalr	-816(ra) # 80004996 <end_op>
  return -1;
    80005cce:	57fd                	li	a5,-1
}
    80005cd0:	853e                	mv	a0,a5
    80005cd2:	70b2                	ld	ra,296(sp)
    80005cd4:	7412                	ld	s0,288(sp)
    80005cd6:	64f2                	ld	s1,280(sp)
    80005cd8:	6952                	ld	s2,272(sp)
    80005cda:	6155                	addi	sp,sp,304
    80005cdc:	8082                	ret

0000000080005cde <sys_unlink>:
{
    80005cde:	7151                	addi	sp,sp,-240
    80005ce0:	f586                	sd	ra,232(sp)
    80005ce2:	f1a2                	sd	s0,224(sp)
    80005ce4:	eda6                	sd	s1,216(sp)
    80005ce6:	e9ca                	sd	s2,208(sp)
    80005ce8:	e5ce                	sd	s3,200(sp)
    80005cea:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cec:	08000613          	li	a2,128
    80005cf0:	f3040593          	addi	a1,s0,-208
    80005cf4:	4501                	li	a0,0
    80005cf6:	ffffd097          	auipc	ra,0xffffd
    80005cfa:	6a4080e7          	jalr	1700(ra) # 8000339a <argstr>
    80005cfe:	18054163          	bltz	a0,80005e80 <sys_unlink+0x1a2>
  begin_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	c14080e7          	jalr	-1004(ra) # 80004916 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d0a:	fb040593          	addi	a1,s0,-80
    80005d0e:	f3040513          	addi	a0,s0,-208
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	a06080e7          	jalr	-1530(ra) # 80004718 <nameiparent>
    80005d1a:	84aa                	mv	s1,a0
    80005d1c:	c979                	beqz	a0,80005df2 <sys_unlink+0x114>
  ilock(dp);
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	226080e7          	jalr	550(ra) # 80003f44 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d26:	00003597          	auipc	a1,0x3
    80005d2a:	a0a58593          	addi	a1,a1,-1526 # 80008730 <syscalls+0x2c8>
    80005d2e:	fb040513          	addi	a0,s0,-80
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	6dc080e7          	jalr	1756(ra) # 8000440e <namecmp>
    80005d3a:	14050a63          	beqz	a0,80005e8e <sys_unlink+0x1b0>
    80005d3e:	00003597          	auipc	a1,0x3
    80005d42:	9fa58593          	addi	a1,a1,-1542 # 80008738 <syscalls+0x2d0>
    80005d46:	fb040513          	addi	a0,s0,-80
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	6c4080e7          	jalr	1732(ra) # 8000440e <namecmp>
    80005d52:	12050e63          	beqz	a0,80005e8e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d56:	f2c40613          	addi	a2,s0,-212
    80005d5a:	fb040593          	addi	a1,s0,-80
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	6c8080e7          	jalr	1736(ra) # 80004428 <dirlookup>
    80005d68:	892a                	mv	s2,a0
    80005d6a:	12050263          	beqz	a0,80005e8e <sys_unlink+0x1b0>
  ilock(ip);
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	1d6080e7          	jalr	470(ra) # 80003f44 <ilock>
  if(ip->nlink < 1)
    80005d76:	04a91783          	lh	a5,74(s2)
    80005d7a:	08f05263          	blez	a5,80005dfe <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d7e:	04491703          	lh	a4,68(s2)
    80005d82:	4785                	li	a5,1
    80005d84:	08f70563          	beq	a4,a5,80005e0e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d88:	4641                	li	a2,16
    80005d8a:	4581                	li	a1,0
    80005d8c:	fc040513          	addi	a0,s0,-64
    80005d90:	ffffb097          	auipc	ra,0xffffb
    80005d94:	f50080e7          	jalr	-176(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d98:	4741                	li	a4,16
    80005d9a:	f2c42683          	lw	a3,-212(s0)
    80005d9e:	fc040613          	addi	a2,s0,-64
    80005da2:	4581                	li	a1,0
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	54a080e7          	jalr	1354(ra) # 800042f0 <writei>
    80005dae:	47c1                	li	a5,16
    80005db0:	0af51563          	bne	a0,a5,80005e5a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005db4:	04491703          	lh	a4,68(s2)
    80005db8:	4785                	li	a5,1
    80005dba:	0af70863          	beq	a4,a5,80005e6a <sys_unlink+0x18c>
  iunlockput(dp);
    80005dbe:	8526                	mv	a0,s1
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	3e6080e7          	jalr	998(ra) # 800041a6 <iunlockput>
  ip->nlink--;
    80005dc8:	04a95783          	lhu	a5,74(s2)
    80005dcc:	37fd                	addiw	a5,a5,-1
    80005dce:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005dd2:	854a                	mv	a0,s2
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	0a6080e7          	jalr	166(ra) # 80003e7a <iupdate>
  iunlockput(ip);
    80005ddc:	854a                	mv	a0,s2
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	3c8080e7          	jalr	968(ra) # 800041a6 <iunlockput>
  end_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	bb0080e7          	jalr	-1104(ra) # 80004996 <end_op>
  return 0;
    80005dee:	4501                	li	a0,0
    80005df0:	a84d                	j	80005ea2 <sys_unlink+0x1c4>
    end_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	ba4080e7          	jalr	-1116(ra) # 80004996 <end_op>
    return -1;
    80005dfa:	557d                	li	a0,-1
    80005dfc:	a05d                	j	80005ea2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dfe:	00003517          	auipc	a0,0x3
    80005e02:	96250513          	addi	a0,a0,-1694 # 80008760 <syscalls+0x2f8>
    80005e06:	ffffa097          	auipc	ra,0xffffa
    80005e0a:	738080e7          	jalr	1848(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e0e:	04c92703          	lw	a4,76(s2)
    80005e12:	02000793          	li	a5,32
    80005e16:	f6e7f9e3          	bgeu	a5,a4,80005d88 <sys_unlink+0xaa>
    80005e1a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e1e:	4741                	li	a4,16
    80005e20:	86ce                	mv	a3,s3
    80005e22:	f1840613          	addi	a2,s0,-232
    80005e26:	4581                	li	a1,0
    80005e28:	854a                	mv	a0,s2
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	3ce080e7          	jalr	974(ra) # 800041f8 <readi>
    80005e32:	47c1                	li	a5,16
    80005e34:	00f51b63          	bne	a0,a5,80005e4a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e38:	f1845783          	lhu	a5,-232(s0)
    80005e3c:	e7a1                	bnez	a5,80005e84 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e3e:	29c1                	addiw	s3,s3,16
    80005e40:	04c92783          	lw	a5,76(s2)
    80005e44:	fcf9ede3          	bltu	s3,a5,80005e1e <sys_unlink+0x140>
    80005e48:	b781                	j	80005d88 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e4a:	00003517          	auipc	a0,0x3
    80005e4e:	92e50513          	addi	a0,a0,-1746 # 80008778 <syscalls+0x310>
    80005e52:	ffffa097          	auipc	ra,0xffffa
    80005e56:	6ec080e7          	jalr	1772(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e5a:	00003517          	auipc	a0,0x3
    80005e5e:	93650513          	addi	a0,a0,-1738 # 80008790 <syscalls+0x328>
    80005e62:	ffffa097          	auipc	ra,0xffffa
    80005e66:	6dc080e7          	jalr	1756(ra) # 8000053e <panic>
    dp->nlink--;
    80005e6a:	04a4d783          	lhu	a5,74(s1)
    80005e6e:	37fd                	addiw	a5,a5,-1
    80005e70:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e74:	8526                	mv	a0,s1
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	004080e7          	jalr	4(ra) # 80003e7a <iupdate>
    80005e7e:	b781                	j	80005dbe <sys_unlink+0xe0>
    return -1;
    80005e80:	557d                	li	a0,-1
    80005e82:	a005                	j	80005ea2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e84:	854a                	mv	a0,s2
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	320080e7          	jalr	800(ra) # 800041a6 <iunlockput>
  iunlockput(dp);
    80005e8e:	8526                	mv	a0,s1
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	316080e7          	jalr	790(ra) # 800041a6 <iunlockput>
  end_op();
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	afe080e7          	jalr	-1282(ra) # 80004996 <end_op>
  return -1;
    80005ea0:	557d                	li	a0,-1
}
    80005ea2:	70ae                	ld	ra,232(sp)
    80005ea4:	740e                	ld	s0,224(sp)
    80005ea6:	64ee                	ld	s1,216(sp)
    80005ea8:	694e                	ld	s2,208(sp)
    80005eaa:	69ae                	ld	s3,200(sp)
    80005eac:	616d                	addi	sp,sp,240
    80005eae:	8082                	ret

0000000080005eb0 <sys_open>:

uint64
sys_open(void)
{
    80005eb0:	7131                	addi	sp,sp,-192
    80005eb2:	fd06                	sd	ra,184(sp)
    80005eb4:	f922                	sd	s0,176(sp)
    80005eb6:	f526                	sd	s1,168(sp)
    80005eb8:	f14a                	sd	s2,160(sp)
    80005eba:	ed4e                	sd	s3,152(sp)
    80005ebc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ebe:	08000613          	li	a2,128
    80005ec2:	f5040593          	addi	a1,s0,-176
    80005ec6:	4501                	li	a0,0
    80005ec8:	ffffd097          	auipc	ra,0xffffd
    80005ecc:	4d2080e7          	jalr	1234(ra) # 8000339a <argstr>
    return -1;
    80005ed0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ed2:	0c054163          	bltz	a0,80005f94 <sys_open+0xe4>
    80005ed6:	f4c40593          	addi	a1,s0,-180
    80005eda:	4505                	li	a0,1
    80005edc:	ffffd097          	auipc	ra,0xffffd
    80005ee0:	47a080e7          	jalr	1146(ra) # 80003356 <argint>
    80005ee4:	0a054863          	bltz	a0,80005f94 <sys_open+0xe4>

  begin_op();
    80005ee8:	fffff097          	auipc	ra,0xfffff
    80005eec:	a2e080e7          	jalr	-1490(ra) # 80004916 <begin_op>

  if(omode & O_CREATE){
    80005ef0:	f4c42783          	lw	a5,-180(s0)
    80005ef4:	2007f793          	andi	a5,a5,512
    80005ef8:	cbdd                	beqz	a5,80005fae <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005efa:	4681                	li	a3,0
    80005efc:	4601                	li	a2,0
    80005efe:	4589                	li	a1,2
    80005f00:	f5040513          	addi	a0,s0,-176
    80005f04:	00000097          	auipc	ra,0x0
    80005f08:	972080e7          	jalr	-1678(ra) # 80005876 <create>
    80005f0c:	892a                	mv	s2,a0
    if(ip == 0){
    80005f0e:	c959                	beqz	a0,80005fa4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f10:	04491703          	lh	a4,68(s2)
    80005f14:	478d                	li	a5,3
    80005f16:	00f71763          	bne	a4,a5,80005f24 <sys_open+0x74>
    80005f1a:	04695703          	lhu	a4,70(s2)
    80005f1e:	47a5                	li	a5,9
    80005f20:	0ce7ec63          	bltu	a5,a4,80005ff8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	e02080e7          	jalr	-510(ra) # 80004d26 <filealloc>
    80005f2c:	89aa                	mv	s3,a0
    80005f2e:	10050263          	beqz	a0,80006032 <sys_open+0x182>
    80005f32:	00000097          	auipc	ra,0x0
    80005f36:	902080e7          	jalr	-1790(ra) # 80005834 <fdalloc>
    80005f3a:	84aa                	mv	s1,a0
    80005f3c:	0e054663          	bltz	a0,80006028 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f40:	04491703          	lh	a4,68(s2)
    80005f44:	478d                	li	a5,3
    80005f46:	0cf70463          	beq	a4,a5,8000600e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f4a:	4789                	li	a5,2
    80005f4c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f50:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f54:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f58:	f4c42783          	lw	a5,-180(s0)
    80005f5c:	0017c713          	xori	a4,a5,1
    80005f60:	8b05                	andi	a4,a4,1
    80005f62:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f66:	0037f713          	andi	a4,a5,3
    80005f6a:	00e03733          	snez	a4,a4
    80005f6e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f72:	4007f793          	andi	a5,a5,1024
    80005f76:	c791                	beqz	a5,80005f82 <sys_open+0xd2>
    80005f78:	04491703          	lh	a4,68(s2)
    80005f7c:	4789                	li	a5,2
    80005f7e:	08f70f63          	beq	a4,a5,8000601c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f82:	854a                	mv	a0,s2
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	082080e7          	jalr	130(ra) # 80004006 <iunlock>
  end_op();
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	a0a080e7          	jalr	-1526(ra) # 80004996 <end_op>

  return fd;
}
    80005f94:	8526                	mv	a0,s1
    80005f96:	70ea                	ld	ra,184(sp)
    80005f98:	744a                	ld	s0,176(sp)
    80005f9a:	74aa                	ld	s1,168(sp)
    80005f9c:	790a                	ld	s2,160(sp)
    80005f9e:	69ea                	ld	s3,152(sp)
    80005fa0:	6129                	addi	sp,sp,192
    80005fa2:	8082                	ret
      end_op();
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	9f2080e7          	jalr	-1550(ra) # 80004996 <end_op>
      return -1;
    80005fac:	b7e5                	j	80005f94 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fae:	f5040513          	addi	a0,s0,-176
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	748080e7          	jalr	1864(ra) # 800046fa <namei>
    80005fba:	892a                	mv	s2,a0
    80005fbc:	c905                	beqz	a0,80005fec <sys_open+0x13c>
    ilock(ip);
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	f86080e7          	jalr	-122(ra) # 80003f44 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fc6:	04491703          	lh	a4,68(s2)
    80005fca:	4785                	li	a5,1
    80005fcc:	f4f712e3          	bne	a4,a5,80005f10 <sys_open+0x60>
    80005fd0:	f4c42783          	lw	a5,-180(s0)
    80005fd4:	dba1                	beqz	a5,80005f24 <sys_open+0x74>
      iunlockput(ip);
    80005fd6:	854a                	mv	a0,s2
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	1ce080e7          	jalr	462(ra) # 800041a6 <iunlockput>
      end_op();
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	9b6080e7          	jalr	-1610(ra) # 80004996 <end_op>
      return -1;
    80005fe8:	54fd                	li	s1,-1
    80005fea:	b76d                	j	80005f94 <sys_open+0xe4>
      end_op();
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	9aa080e7          	jalr	-1622(ra) # 80004996 <end_op>
      return -1;
    80005ff4:	54fd                	li	s1,-1
    80005ff6:	bf79                	j	80005f94 <sys_open+0xe4>
    iunlockput(ip);
    80005ff8:	854a                	mv	a0,s2
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	1ac080e7          	jalr	428(ra) # 800041a6 <iunlockput>
    end_op();
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	994080e7          	jalr	-1644(ra) # 80004996 <end_op>
    return -1;
    8000600a:	54fd                	li	s1,-1
    8000600c:	b761                	j	80005f94 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000600e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006012:	04691783          	lh	a5,70(s2)
    80006016:	02f99223          	sh	a5,36(s3)
    8000601a:	bf2d                	j	80005f54 <sys_open+0xa4>
    itrunc(ip);
    8000601c:	854a                	mv	a0,s2
    8000601e:	ffffe097          	auipc	ra,0xffffe
    80006022:	034080e7          	jalr	52(ra) # 80004052 <itrunc>
    80006026:	bfb1                	j	80005f82 <sys_open+0xd2>
      fileclose(f);
    80006028:	854e                	mv	a0,s3
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	db8080e7          	jalr	-584(ra) # 80004de2 <fileclose>
    iunlockput(ip);
    80006032:	854a                	mv	a0,s2
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	172080e7          	jalr	370(ra) # 800041a6 <iunlockput>
    end_op();
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	95a080e7          	jalr	-1702(ra) # 80004996 <end_op>
    return -1;
    80006044:	54fd                	li	s1,-1
    80006046:	b7b9                	j	80005f94 <sys_open+0xe4>

0000000080006048 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006048:	7175                	addi	sp,sp,-144
    8000604a:	e506                	sd	ra,136(sp)
    8000604c:	e122                	sd	s0,128(sp)
    8000604e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006050:	fffff097          	auipc	ra,0xfffff
    80006054:	8c6080e7          	jalr	-1850(ra) # 80004916 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006058:	08000613          	li	a2,128
    8000605c:	f7040593          	addi	a1,s0,-144
    80006060:	4501                	li	a0,0
    80006062:	ffffd097          	auipc	ra,0xffffd
    80006066:	338080e7          	jalr	824(ra) # 8000339a <argstr>
    8000606a:	02054963          	bltz	a0,8000609c <sys_mkdir+0x54>
    8000606e:	4681                	li	a3,0
    80006070:	4601                	li	a2,0
    80006072:	4585                	li	a1,1
    80006074:	f7040513          	addi	a0,s0,-144
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	7fe080e7          	jalr	2046(ra) # 80005876 <create>
    80006080:	cd11                	beqz	a0,8000609c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006082:	ffffe097          	auipc	ra,0xffffe
    80006086:	124080e7          	jalr	292(ra) # 800041a6 <iunlockput>
  end_op();
    8000608a:	fffff097          	auipc	ra,0xfffff
    8000608e:	90c080e7          	jalr	-1780(ra) # 80004996 <end_op>
  return 0;
    80006092:	4501                	li	a0,0
}
    80006094:	60aa                	ld	ra,136(sp)
    80006096:	640a                	ld	s0,128(sp)
    80006098:	6149                	addi	sp,sp,144
    8000609a:	8082                	ret
    end_op();
    8000609c:	fffff097          	auipc	ra,0xfffff
    800060a0:	8fa080e7          	jalr	-1798(ra) # 80004996 <end_op>
    return -1;
    800060a4:	557d                	li	a0,-1
    800060a6:	b7fd                	j	80006094 <sys_mkdir+0x4c>

00000000800060a8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060a8:	7135                	addi	sp,sp,-160
    800060aa:	ed06                	sd	ra,152(sp)
    800060ac:	e922                	sd	s0,144(sp)
    800060ae:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	866080e7          	jalr	-1946(ra) # 80004916 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060b8:	08000613          	li	a2,128
    800060bc:	f7040593          	addi	a1,s0,-144
    800060c0:	4501                	li	a0,0
    800060c2:	ffffd097          	auipc	ra,0xffffd
    800060c6:	2d8080e7          	jalr	728(ra) # 8000339a <argstr>
    800060ca:	04054a63          	bltz	a0,8000611e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800060ce:	f6c40593          	addi	a1,s0,-148
    800060d2:	4505                	li	a0,1
    800060d4:	ffffd097          	auipc	ra,0xffffd
    800060d8:	282080e7          	jalr	642(ra) # 80003356 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060dc:	04054163          	bltz	a0,8000611e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060e0:	f6840593          	addi	a1,s0,-152
    800060e4:	4509                	li	a0,2
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	270080e7          	jalr	624(ra) # 80003356 <argint>
     argint(1, &major) < 0 ||
    800060ee:	02054863          	bltz	a0,8000611e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060f2:	f6841683          	lh	a3,-152(s0)
    800060f6:	f6c41603          	lh	a2,-148(s0)
    800060fa:	458d                	li	a1,3
    800060fc:	f7040513          	addi	a0,s0,-144
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	776080e7          	jalr	1910(ra) # 80005876 <create>
     argint(2, &minor) < 0 ||
    80006108:	c919                	beqz	a0,8000611e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000610a:	ffffe097          	auipc	ra,0xffffe
    8000610e:	09c080e7          	jalr	156(ra) # 800041a6 <iunlockput>
  end_op();
    80006112:	fffff097          	auipc	ra,0xfffff
    80006116:	884080e7          	jalr	-1916(ra) # 80004996 <end_op>
  return 0;
    8000611a:	4501                	li	a0,0
    8000611c:	a031                	j	80006128 <sys_mknod+0x80>
    end_op();
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	878080e7          	jalr	-1928(ra) # 80004996 <end_op>
    return -1;
    80006126:	557d                	li	a0,-1
}
    80006128:	60ea                	ld	ra,152(sp)
    8000612a:	644a                	ld	s0,144(sp)
    8000612c:	610d                	addi	sp,sp,160
    8000612e:	8082                	ret

0000000080006130 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006130:	7135                	addi	sp,sp,-160
    80006132:	ed06                	sd	ra,152(sp)
    80006134:	e922                	sd	s0,144(sp)
    80006136:	e526                	sd	s1,136(sp)
    80006138:	e14a                	sd	s2,128(sp)
    8000613a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	7ca080e7          	jalr	1994(ra) # 80001906 <myproc>
    80006144:	892a                	mv	s2,a0
  
  begin_op();
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	7d0080e7          	jalr	2000(ra) # 80004916 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000614e:	08000613          	li	a2,128
    80006152:	f6040593          	addi	a1,s0,-160
    80006156:	4501                	li	a0,0
    80006158:	ffffd097          	auipc	ra,0xffffd
    8000615c:	242080e7          	jalr	578(ra) # 8000339a <argstr>
    80006160:	04054b63          	bltz	a0,800061b6 <sys_chdir+0x86>
    80006164:	f6040513          	addi	a0,s0,-160
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	592080e7          	jalr	1426(ra) # 800046fa <namei>
    80006170:	84aa                	mv	s1,a0
    80006172:	c131                	beqz	a0,800061b6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006174:	ffffe097          	auipc	ra,0xffffe
    80006178:	dd0080e7          	jalr	-560(ra) # 80003f44 <ilock>
  if(ip->type != T_DIR){
    8000617c:	04449703          	lh	a4,68(s1)
    80006180:	4785                	li	a5,1
    80006182:	04f71063          	bne	a4,a5,800061c2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006186:	8526                	mv	a0,s1
    80006188:	ffffe097          	auipc	ra,0xffffe
    8000618c:	e7e080e7          	jalr	-386(ra) # 80004006 <iunlock>
  iput(p->cwd);
    80006190:	17893503          	ld	a0,376(s2)
    80006194:	ffffe097          	auipc	ra,0xffffe
    80006198:	f6a080e7          	jalr	-150(ra) # 800040fe <iput>
  end_op();
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	7fa080e7          	jalr	2042(ra) # 80004996 <end_op>
  p->cwd = ip;
    800061a4:	16993c23          	sd	s1,376(s2)
  return 0;
    800061a8:	4501                	li	a0,0
}
    800061aa:	60ea                	ld	ra,152(sp)
    800061ac:	644a                	ld	s0,144(sp)
    800061ae:	64aa                	ld	s1,136(sp)
    800061b0:	690a                	ld	s2,128(sp)
    800061b2:	610d                	addi	sp,sp,160
    800061b4:	8082                	ret
    end_op();
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	7e0080e7          	jalr	2016(ra) # 80004996 <end_op>
    return -1;
    800061be:	557d                	li	a0,-1
    800061c0:	b7ed                	j	800061aa <sys_chdir+0x7a>
    iunlockput(ip);
    800061c2:	8526                	mv	a0,s1
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	fe2080e7          	jalr	-30(ra) # 800041a6 <iunlockput>
    end_op();
    800061cc:	ffffe097          	auipc	ra,0xffffe
    800061d0:	7ca080e7          	jalr	1994(ra) # 80004996 <end_op>
    return -1;
    800061d4:	557d                	li	a0,-1
    800061d6:	bfd1                	j	800061aa <sys_chdir+0x7a>

00000000800061d8 <sys_exec>:

uint64
sys_exec(void)
{
    800061d8:	7145                	addi	sp,sp,-464
    800061da:	e786                	sd	ra,456(sp)
    800061dc:	e3a2                	sd	s0,448(sp)
    800061de:	ff26                	sd	s1,440(sp)
    800061e0:	fb4a                	sd	s2,432(sp)
    800061e2:	f74e                	sd	s3,424(sp)
    800061e4:	f352                	sd	s4,416(sp)
    800061e6:	ef56                	sd	s5,408(sp)
    800061e8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061ea:	08000613          	li	a2,128
    800061ee:	f4040593          	addi	a1,s0,-192
    800061f2:	4501                	li	a0,0
    800061f4:	ffffd097          	auipc	ra,0xffffd
    800061f8:	1a6080e7          	jalr	422(ra) # 8000339a <argstr>
    return -1;
    800061fc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061fe:	0c054a63          	bltz	a0,800062d2 <sys_exec+0xfa>
    80006202:	e3840593          	addi	a1,s0,-456
    80006206:	4505                	li	a0,1
    80006208:	ffffd097          	auipc	ra,0xffffd
    8000620c:	170080e7          	jalr	368(ra) # 80003378 <argaddr>
    80006210:	0c054163          	bltz	a0,800062d2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006214:	10000613          	li	a2,256
    80006218:	4581                	li	a1,0
    8000621a:	e4040513          	addi	a0,s0,-448
    8000621e:	ffffb097          	auipc	ra,0xffffb
    80006222:	ac2080e7          	jalr	-1342(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006226:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000622a:	89a6                	mv	s3,s1
    8000622c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000622e:	02000a13          	li	s4,32
    80006232:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006236:	00391513          	slli	a0,s2,0x3
    8000623a:	e3040593          	addi	a1,s0,-464
    8000623e:	e3843783          	ld	a5,-456(s0)
    80006242:	953e                	add	a0,a0,a5
    80006244:	ffffd097          	auipc	ra,0xffffd
    80006248:	078080e7          	jalr	120(ra) # 800032bc <fetchaddr>
    8000624c:	02054a63          	bltz	a0,80006280 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006250:	e3043783          	ld	a5,-464(s0)
    80006254:	c3b9                	beqz	a5,8000629a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006256:	ffffb097          	auipc	ra,0xffffb
    8000625a:	89e080e7          	jalr	-1890(ra) # 80000af4 <kalloc>
    8000625e:	85aa                	mv	a1,a0
    80006260:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006264:	cd11                	beqz	a0,80006280 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006266:	6605                	lui	a2,0x1
    80006268:	e3043503          	ld	a0,-464(s0)
    8000626c:	ffffd097          	auipc	ra,0xffffd
    80006270:	0a2080e7          	jalr	162(ra) # 8000330e <fetchstr>
    80006274:	00054663          	bltz	a0,80006280 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006278:	0905                	addi	s2,s2,1
    8000627a:	09a1                	addi	s3,s3,8
    8000627c:	fb491be3          	bne	s2,s4,80006232 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006280:	10048913          	addi	s2,s1,256
    80006284:	6088                	ld	a0,0(s1)
    80006286:	c529                	beqz	a0,800062d0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006288:	ffffa097          	auipc	ra,0xffffa
    8000628c:	770080e7          	jalr	1904(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006290:	04a1                	addi	s1,s1,8
    80006292:	ff2499e3          	bne	s1,s2,80006284 <sys_exec+0xac>
  return -1;
    80006296:	597d                	li	s2,-1
    80006298:	a82d                	j	800062d2 <sys_exec+0xfa>
      argv[i] = 0;
    8000629a:	0a8e                	slli	s5,s5,0x3
    8000629c:	fc040793          	addi	a5,s0,-64
    800062a0:	9abe                	add	s5,s5,a5
    800062a2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062a6:	e4040593          	addi	a1,s0,-448
    800062aa:	f4040513          	addi	a0,s0,-192
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	194080e7          	jalr	404(ra) # 80005442 <exec>
    800062b6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062b8:	10048993          	addi	s3,s1,256
    800062bc:	6088                	ld	a0,0(s1)
    800062be:	c911                	beqz	a0,800062d2 <sys_exec+0xfa>
    kfree(argv[i]);
    800062c0:	ffffa097          	auipc	ra,0xffffa
    800062c4:	738080e7          	jalr	1848(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062c8:	04a1                	addi	s1,s1,8
    800062ca:	ff3499e3          	bne	s1,s3,800062bc <sys_exec+0xe4>
    800062ce:	a011                	j	800062d2 <sys_exec+0xfa>
  return -1;
    800062d0:	597d                	li	s2,-1
}
    800062d2:	854a                	mv	a0,s2
    800062d4:	60be                	ld	ra,456(sp)
    800062d6:	641e                	ld	s0,448(sp)
    800062d8:	74fa                	ld	s1,440(sp)
    800062da:	795a                	ld	s2,432(sp)
    800062dc:	79ba                	ld	s3,424(sp)
    800062de:	7a1a                	ld	s4,416(sp)
    800062e0:	6afa                	ld	s5,408(sp)
    800062e2:	6179                	addi	sp,sp,464
    800062e4:	8082                	ret

00000000800062e6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062e6:	7139                	addi	sp,sp,-64
    800062e8:	fc06                	sd	ra,56(sp)
    800062ea:	f822                	sd	s0,48(sp)
    800062ec:	f426                	sd	s1,40(sp)
    800062ee:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	616080e7          	jalr	1558(ra) # 80001906 <myproc>
    800062f8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062fa:	fd840593          	addi	a1,s0,-40
    800062fe:	4501                	li	a0,0
    80006300:	ffffd097          	auipc	ra,0xffffd
    80006304:	078080e7          	jalr	120(ra) # 80003378 <argaddr>
    return -1;
    80006308:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000630a:	0e054063          	bltz	a0,800063ea <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000630e:	fc840593          	addi	a1,s0,-56
    80006312:	fd040513          	addi	a0,s0,-48
    80006316:	fffff097          	auipc	ra,0xfffff
    8000631a:	dfc080e7          	jalr	-516(ra) # 80005112 <pipealloc>
    return -1;
    8000631e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006320:	0c054563          	bltz	a0,800063ea <sys_pipe+0x104>
  fd0 = -1;
    80006324:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006328:	fd043503          	ld	a0,-48(s0)
    8000632c:	fffff097          	auipc	ra,0xfffff
    80006330:	508080e7          	jalr	1288(ra) # 80005834 <fdalloc>
    80006334:	fca42223          	sw	a0,-60(s0)
    80006338:	08054c63          	bltz	a0,800063d0 <sys_pipe+0xea>
    8000633c:	fc843503          	ld	a0,-56(s0)
    80006340:	fffff097          	auipc	ra,0xfffff
    80006344:	4f4080e7          	jalr	1268(ra) # 80005834 <fdalloc>
    80006348:	fca42023          	sw	a0,-64(s0)
    8000634c:	06054863          	bltz	a0,800063bc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006350:	4691                	li	a3,4
    80006352:	fc440613          	addi	a2,s0,-60
    80006356:	fd843583          	ld	a1,-40(s0)
    8000635a:	7ca8                	ld	a0,120(s1)
    8000635c:	ffffb097          	auipc	ra,0xffffb
    80006360:	316080e7          	jalr	790(ra) # 80001672 <copyout>
    80006364:	02054063          	bltz	a0,80006384 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006368:	4691                	li	a3,4
    8000636a:	fc040613          	addi	a2,s0,-64
    8000636e:	fd843583          	ld	a1,-40(s0)
    80006372:	0591                	addi	a1,a1,4
    80006374:	7ca8                	ld	a0,120(s1)
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	2fc080e7          	jalr	764(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000637e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006380:	06055563          	bgez	a0,800063ea <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006384:	fc442783          	lw	a5,-60(s0)
    80006388:	07f9                	addi	a5,a5,30
    8000638a:	078e                	slli	a5,a5,0x3
    8000638c:	97a6                	add	a5,a5,s1
    8000638e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006392:	fc042503          	lw	a0,-64(s0)
    80006396:	0579                	addi	a0,a0,30
    80006398:	050e                	slli	a0,a0,0x3
    8000639a:	9526                	add	a0,a0,s1
    8000639c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800063a0:	fd043503          	ld	a0,-48(s0)
    800063a4:	fffff097          	auipc	ra,0xfffff
    800063a8:	a3e080e7          	jalr	-1474(ra) # 80004de2 <fileclose>
    fileclose(wf);
    800063ac:	fc843503          	ld	a0,-56(s0)
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	a32080e7          	jalr	-1486(ra) # 80004de2 <fileclose>
    return -1;
    800063b8:	57fd                	li	a5,-1
    800063ba:	a805                	j	800063ea <sys_pipe+0x104>
    if(fd0 >= 0)
    800063bc:	fc442783          	lw	a5,-60(s0)
    800063c0:	0007c863          	bltz	a5,800063d0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800063c4:	01e78513          	addi	a0,a5,30
    800063c8:	050e                	slli	a0,a0,0x3
    800063ca:	9526                	add	a0,a0,s1
    800063cc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800063d0:	fd043503          	ld	a0,-48(s0)
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	a0e080e7          	jalr	-1522(ra) # 80004de2 <fileclose>
    fileclose(wf);
    800063dc:	fc843503          	ld	a0,-56(s0)
    800063e0:	fffff097          	auipc	ra,0xfffff
    800063e4:	a02080e7          	jalr	-1534(ra) # 80004de2 <fileclose>
    return -1;
    800063e8:	57fd                	li	a5,-1
}
    800063ea:	853e                	mv	a0,a5
    800063ec:	70e2                	ld	ra,56(sp)
    800063ee:	7442                	ld	s0,48(sp)
    800063f0:	74a2                	ld	s1,40(sp)
    800063f2:	6121                	addi	sp,sp,64
    800063f4:	8082                	ret
	...

0000000080006400 <kernelvec>:
    80006400:	7111                	addi	sp,sp,-256
    80006402:	e006                	sd	ra,0(sp)
    80006404:	e40a                	sd	sp,8(sp)
    80006406:	e80e                	sd	gp,16(sp)
    80006408:	ec12                	sd	tp,24(sp)
    8000640a:	f016                	sd	t0,32(sp)
    8000640c:	f41a                	sd	t1,40(sp)
    8000640e:	f81e                	sd	t2,48(sp)
    80006410:	fc22                	sd	s0,56(sp)
    80006412:	e0a6                	sd	s1,64(sp)
    80006414:	e4aa                	sd	a0,72(sp)
    80006416:	e8ae                	sd	a1,80(sp)
    80006418:	ecb2                	sd	a2,88(sp)
    8000641a:	f0b6                	sd	a3,96(sp)
    8000641c:	f4ba                	sd	a4,104(sp)
    8000641e:	f8be                	sd	a5,112(sp)
    80006420:	fcc2                	sd	a6,120(sp)
    80006422:	e146                	sd	a7,128(sp)
    80006424:	e54a                	sd	s2,136(sp)
    80006426:	e94e                	sd	s3,144(sp)
    80006428:	ed52                	sd	s4,152(sp)
    8000642a:	f156                	sd	s5,160(sp)
    8000642c:	f55a                	sd	s6,168(sp)
    8000642e:	f95e                	sd	s7,176(sp)
    80006430:	fd62                	sd	s8,184(sp)
    80006432:	e1e6                	sd	s9,192(sp)
    80006434:	e5ea                	sd	s10,200(sp)
    80006436:	e9ee                	sd	s11,208(sp)
    80006438:	edf2                	sd	t3,216(sp)
    8000643a:	f1f6                	sd	t4,224(sp)
    8000643c:	f5fa                	sd	t5,232(sp)
    8000643e:	f9fe                	sd	t6,240(sp)
    80006440:	d49fc0ef          	jal	ra,80003188 <kerneltrap>
    80006444:	6082                	ld	ra,0(sp)
    80006446:	6122                	ld	sp,8(sp)
    80006448:	61c2                	ld	gp,16(sp)
    8000644a:	7282                	ld	t0,32(sp)
    8000644c:	7322                	ld	t1,40(sp)
    8000644e:	73c2                	ld	t2,48(sp)
    80006450:	7462                	ld	s0,56(sp)
    80006452:	6486                	ld	s1,64(sp)
    80006454:	6526                	ld	a0,72(sp)
    80006456:	65c6                	ld	a1,80(sp)
    80006458:	6666                	ld	a2,88(sp)
    8000645a:	7686                	ld	a3,96(sp)
    8000645c:	7726                	ld	a4,104(sp)
    8000645e:	77c6                	ld	a5,112(sp)
    80006460:	7866                	ld	a6,120(sp)
    80006462:	688a                	ld	a7,128(sp)
    80006464:	692a                	ld	s2,136(sp)
    80006466:	69ca                	ld	s3,144(sp)
    80006468:	6a6a                	ld	s4,152(sp)
    8000646a:	7a8a                	ld	s5,160(sp)
    8000646c:	7b2a                	ld	s6,168(sp)
    8000646e:	7bca                	ld	s7,176(sp)
    80006470:	7c6a                	ld	s8,184(sp)
    80006472:	6c8e                	ld	s9,192(sp)
    80006474:	6d2e                	ld	s10,200(sp)
    80006476:	6dce                	ld	s11,208(sp)
    80006478:	6e6e                	ld	t3,216(sp)
    8000647a:	7e8e                	ld	t4,224(sp)
    8000647c:	7f2e                	ld	t5,232(sp)
    8000647e:	7fce                	ld	t6,240(sp)
    80006480:	6111                	addi	sp,sp,256
    80006482:	10200073          	sret
    80006486:	00000013          	nop
    8000648a:	00000013          	nop
    8000648e:	0001                	nop

0000000080006490 <timervec>:
    80006490:	34051573          	csrrw	a0,mscratch,a0
    80006494:	e10c                	sd	a1,0(a0)
    80006496:	e510                	sd	a2,8(a0)
    80006498:	e914                	sd	a3,16(a0)
    8000649a:	6d0c                	ld	a1,24(a0)
    8000649c:	7110                	ld	a2,32(a0)
    8000649e:	6194                	ld	a3,0(a1)
    800064a0:	96b2                	add	a3,a3,a2
    800064a2:	e194                	sd	a3,0(a1)
    800064a4:	4589                	li	a1,2
    800064a6:	14459073          	csrw	sip,a1
    800064aa:	6914                	ld	a3,16(a0)
    800064ac:	6510                	ld	a2,8(a0)
    800064ae:	610c                	ld	a1,0(a0)
    800064b0:	34051573          	csrrw	a0,mscratch,a0
    800064b4:	30200073          	mret
	...

00000000800064ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064ba:	1141                	addi	sp,sp,-16
    800064bc:	e422                	sd	s0,8(sp)
    800064be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064c0:	0c0007b7          	lui	a5,0xc000
    800064c4:	4705                	li	a4,1
    800064c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064c8:	c3d8                	sw	a4,4(a5)
}
    800064ca:	6422                	ld	s0,8(sp)
    800064cc:	0141                	addi	sp,sp,16
    800064ce:	8082                	ret

00000000800064d0 <plicinithart>:

void
plicinithart(void)
{
    800064d0:	1141                	addi	sp,sp,-16
    800064d2:	e406                	sd	ra,8(sp)
    800064d4:	e022                	sd	s0,0(sp)
    800064d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064d8:	ffffb097          	auipc	ra,0xffffb
    800064dc:	3fc080e7          	jalr	1020(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064e0:	0085171b          	slliw	a4,a0,0x8
    800064e4:	0c0027b7          	lui	a5,0xc002
    800064e8:	97ba                	add	a5,a5,a4
    800064ea:	40200713          	li	a4,1026
    800064ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064f2:	00d5151b          	slliw	a0,a0,0xd
    800064f6:	0c2017b7          	lui	a5,0xc201
    800064fa:	953e                	add	a0,a0,a5
    800064fc:	00052023          	sw	zero,0(a0)
}
    80006500:	60a2                	ld	ra,8(sp)
    80006502:	6402                	ld	s0,0(sp)
    80006504:	0141                	addi	sp,sp,16
    80006506:	8082                	ret

0000000080006508 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006508:	1141                	addi	sp,sp,-16
    8000650a:	e406                	sd	ra,8(sp)
    8000650c:	e022                	sd	s0,0(sp)
    8000650e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006510:	ffffb097          	auipc	ra,0xffffb
    80006514:	3c4080e7          	jalr	964(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006518:	00d5179b          	slliw	a5,a0,0xd
    8000651c:	0c201537          	lui	a0,0xc201
    80006520:	953e                	add	a0,a0,a5
  return irq;
}
    80006522:	4148                	lw	a0,4(a0)
    80006524:	60a2                	ld	ra,8(sp)
    80006526:	6402                	ld	s0,0(sp)
    80006528:	0141                	addi	sp,sp,16
    8000652a:	8082                	ret

000000008000652c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000652c:	1101                	addi	sp,sp,-32
    8000652e:	ec06                	sd	ra,24(sp)
    80006530:	e822                	sd	s0,16(sp)
    80006532:	e426                	sd	s1,8(sp)
    80006534:	1000                	addi	s0,sp,32
    80006536:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006538:	ffffb097          	auipc	ra,0xffffb
    8000653c:	39c080e7          	jalr	924(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006540:	00d5151b          	slliw	a0,a0,0xd
    80006544:	0c2017b7          	lui	a5,0xc201
    80006548:	97aa                	add	a5,a5,a0
    8000654a:	c3c4                	sw	s1,4(a5)
}
    8000654c:	60e2                	ld	ra,24(sp)
    8000654e:	6442                	ld	s0,16(sp)
    80006550:	64a2                	ld	s1,8(sp)
    80006552:	6105                	addi	sp,sp,32
    80006554:	8082                	ret

0000000080006556 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006556:	1141                	addi	sp,sp,-16
    80006558:	e406                	sd	ra,8(sp)
    8000655a:	e022                	sd	s0,0(sp)
    8000655c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000655e:	479d                	li	a5,7
    80006560:	06a7c963          	blt	a5,a0,800065d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006564:	0001e797          	auipc	a5,0x1e
    80006568:	a9c78793          	addi	a5,a5,-1380 # 80024000 <disk>
    8000656c:	00a78733          	add	a4,a5,a0
    80006570:	6789                	lui	a5,0x2
    80006572:	97ba                	add	a5,a5,a4
    80006574:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006578:	e7ad                	bnez	a5,800065e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000657a:	00451793          	slli	a5,a0,0x4
    8000657e:	00020717          	auipc	a4,0x20
    80006582:	a8270713          	addi	a4,a4,-1406 # 80026000 <disk+0x2000>
    80006586:	6314                	ld	a3,0(a4)
    80006588:	96be                	add	a3,a3,a5
    8000658a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000658e:	6314                	ld	a3,0(a4)
    80006590:	96be                	add	a3,a3,a5
    80006592:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006596:	6314                	ld	a3,0(a4)
    80006598:	96be                	add	a3,a3,a5
    8000659a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000659e:	6318                	ld	a4,0(a4)
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800065a6:	0001e797          	auipc	a5,0x1e
    800065aa:	a5a78793          	addi	a5,a5,-1446 # 80024000 <disk>
    800065ae:	97aa                	add	a5,a5,a0
    800065b0:	6509                	lui	a0,0x2
    800065b2:	953e                	add	a0,a0,a5
    800065b4:	4785                	li	a5,1
    800065b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800065ba:	00020517          	auipc	a0,0x20
    800065be:	a5e50513          	addi	a0,a0,-1442 # 80026018 <disk+0x2018>
    800065c2:	ffffc097          	auipc	ra,0xffffc
    800065c6:	a80080e7          	jalr	-1408(ra) # 80002042 <wakeup>
}
    800065ca:	60a2                	ld	ra,8(sp)
    800065cc:	6402                	ld	s0,0(sp)
    800065ce:	0141                	addi	sp,sp,16
    800065d0:	8082                	ret
    panic("free_desc 1");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	1ce50513          	addi	a0,a0,462 # 800087a0 <syscalls+0x338>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f64080e7          	jalr	-156(ra) # 8000053e <panic>
    panic("free_desc 2");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	1ce50513          	addi	a0,a0,462 # 800087b0 <syscalls+0x348>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f54080e7          	jalr	-172(ra) # 8000053e <panic>

00000000800065f2 <virtio_disk_init>:
{
    800065f2:	1101                	addi	sp,sp,-32
    800065f4:	ec06                	sd	ra,24(sp)
    800065f6:	e822                	sd	s0,16(sp)
    800065f8:	e426                	sd	s1,8(sp)
    800065fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065fc:	00002597          	auipc	a1,0x2
    80006600:	1c458593          	addi	a1,a1,452 # 800087c0 <syscalls+0x358>
    80006604:	00020517          	auipc	a0,0x20
    80006608:	b2450513          	addi	a0,a0,-1244 # 80026128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	548080e7          	jalr	1352(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006614:	100017b7          	lui	a5,0x10001
    80006618:	4398                	lw	a4,0(a5)
    8000661a:	2701                	sext.w	a4,a4
    8000661c:	747277b7          	lui	a5,0x74727
    80006620:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006624:	0ef71163          	bne	a4,a5,80006706 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	43dc                	lw	a5,4(a5)
    8000662e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006630:	4705                	li	a4,1
    80006632:	0ce79a63          	bne	a5,a4,80006706 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006636:	100017b7          	lui	a5,0x10001
    8000663a:	479c                	lw	a5,8(a5)
    8000663c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000663e:	4709                	li	a4,2
    80006640:	0ce79363          	bne	a5,a4,80006706 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006644:	100017b7          	lui	a5,0x10001
    80006648:	47d8                	lw	a4,12(a5)
    8000664a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000664c:	554d47b7          	lui	a5,0x554d4
    80006650:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006654:	0af71963          	bne	a4,a5,80006706 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006658:	100017b7          	lui	a5,0x10001
    8000665c:	4705                	li	a4,1
    8000665e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006660:	470d                	li	a4,3
    80006662:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006664:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006666:	c7ffe737          	lui	a4,0xc7ffe
    8000666a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    8000666e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006670:	2701                	sext.w	a4,a4
    80006672:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006674:	472d                	li	a4,11
    80006676:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006678:	473d                	li	a4,15
    8000667a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000667c:	6705                	lui	a4,0x1
    8000667e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006680:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006684:	5bdc                	lw	a5,52(a5)
    80006686:	2781                	sext.w	a5,a5
  if(max == 0)
    80006688:	c7d9                	beqz	a5,80006716 <virtio_disk_init+0x124>
  if(max < NUM)
    8000668a:	471d                	li	a4,7
    8000668c:	08f77d63          	bgeu	a4,a5,80006726 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006690:	100014b7          	lui	s1,0x10001
    80006694:	47a1                	li	a5,8
    80006696:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006698:	6609                	lui	a2,0x2
    8000669a:	4581                	li	a1,0
    8000669c:	0001e517          	auipc	a0,0x1e
    800066a0:	96450513          	addi	a0,a0,-1692 # 80024000 <disk>
    800066a4:	ffffa097          	auipc	ra,0xffffa
    800066a8:	63c080e7          	jalr	1596(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800066ac:	0001e717          	auipc	a4,0x1e
    800066b0:	95470713          	addi	a4,a4,-1708 # 80024000 <disk>
    800066b4:	00c75793          	srli	a5,a4,0xc
    800066b8:	2781                	sext.w	a5,a5
    800066ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800066bc:	00020797          	auipc	a5,0x20
    800066c0:	94478793          	addi	a5,a5,-1724 # 80026000 <disk+0x2000>
    800066c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800066c6:	0001e717          	auipc	a4,0x1e
    800066ca:	9ba70713          	addi	a4,a4,-1606 # 80024080 <disk+0x80>
    800066ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066d0:	0001f717          	auipc	a4,0x1f
    800066d4:	93070713          	addi	a4,a4,-1744 # 80025000 <disk+0x1000>
    800066d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066da:	4705                	li	a4,1
    800066dc:	00e78c23          	sb	a4,24(a5)
    800066e0:	00e78ca3          	sb	a4,25(a5)
    800066e4:	00e78d23          	sb	a4,26(a5)
    800066e8:	00e78da3          	sb	a4,27(a5)
    800066ec:	00e78e23          	sb	a4,28(a5)
    800066f0:	00e78ea3          	sb	a4,29(a5)
    800066f4:	00e78f23          	sb	a4,30(a5)
    800066f8:	00e78fa3          	sb	a4,31(a5)
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret
    panic("could not find virtio disk");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	0ca50513          	addi	a0,a0,202 # 800087d0 <syscalls+0x368>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006716:	00002517          	auipc	a0,0x2
    8000671a:	0da50513          	addi	a0,a0,218 # 800087f0 <syscalls+0x388>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006726:	00002517          	auipc	a0,0x2
    8000672a:	0ea50513          	addi	a0,a0,234 # 80008810 <syscalls+0x3a8>
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>

0000000080006736 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006736:	7159                	addi	sp,sp,-112
    80006738:	f486                	sd	ra,104(sp)
    8000673a:	f0a2                	sd	s0,96(sp)
    8000673c:	eca6                	sd	s1,88(sp)
    8000673e:	e8ca                	sd	s2,80(sp)
    80006740:	e4ce                	sd	s3,72(sp)
    80006742:	e0d2                	sd	s4,64(sp)
    80006744:	fc56                	sd	s5,56(sp)
    80006746:	f85a                	sd	s6,48(sp)
    80006748:	f45e                	sd	s7,40(sp)
    8000674a:	f062                	sd	s8,32(sp)
    8000674c:	ec66                	sd	s9,24(sp)
    8000674e:	e86a                	sd	s10,16(sp)
    80006750:	1880                	addi	s0,sp,112
    80006752:	892a                	mv	s2,a0
    80006754:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006756:	00c52c83          	lw	s9,12(a0)
    8000675a:	001c9c9b          	slliw	s9,s9,0x1
    8000675e:	1c82                	slli	s9,s9,0x20
    80006760:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006764:	00020517          	auipc	a0,0x20
    80006768:	9c450513          	addi	a0,a0,-1596 # 80026128 <disk+0x2128>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	478080e7          	jalr	1144(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006774:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006776:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006778:	0001eb97          	auipc	s7,0x1e
    8000677c:	888b8b93          	addi	s7,s7,-1912 # 80024000 <disk>
    80006780:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006782:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006784:	8a4e                	mv	s4,s3
    80006786:	a051                	j	8000680a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006788:	00fb86b3          	add	a3,s7,a5
    8000678c:	96da                	add	a3,a3,s6
    8000678e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006792:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006794:	0207c563          	bltz	a5,800067be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006798:	2485                	addiw	s1,s1,1
    8000679a:	0711                	addi	a4,a4,4
    8000679c:	25548063          	beq	s1,s5,800069dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800067a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800067a2:	00020697          	auipc	a3,0x20
    800067a6:	87668693          	addi	a3,a3,-1930 # 80026018 <disk+0x2018>
    800067aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800067ac:	0006c583          	lbu	a1,0(a3)
    800067b0:	fde1                	bnez	a1,80006788 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800067b2:	2785                	addiw	a5,a5,1
    800067b4:	0685                	addi	a3,a3,1
    800067b6:	ff879be3          	bne	a5,s8,800067ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800067ba:	57fd                	li	a5,-1
    800067bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800067be:	02905a63          	blez	s1,800067f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067c2:	f9042503          	lw	a0,-112(s0)
    800067c6:	00000097          	auipc	ra,0x0
    800067ca:	d90080e7          	jalr	-624(ra) # 80006556 <free_desc>
      for(int j = 0; j < i; j++)
    800067ce:	4785                	li	a5,1
    800067d0:	0297d163          	bge	a5,s1,800067f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067d4:	f9442503          	lw	a0,-108(s0)
    800067d8:	00000097          	auipc	ra,0x0
    800067dc:	d7e080e7          	jalr	-642(ra) # 80006556 <free_desc>
      for(int j = 0; j < i; j++)
    800067e0:	4789                	li	a5,2
    800067e2:	0097d863          	bge	a5,s1,800067f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067e6:	f9842503          	lw	a0,-104(s0)
    800067ea:	00000097          	auipc	ra,0x0
    800067ee:	d6c080e7          	jalr	-660(ra) # 80006556 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067f2:	00020597          	auipc	a1,0x20
    800067f6:	93658593          	addi	a1,a1,-1738 # 80026128 <disk+0x2128>
    800067fa:	00020517          	auipc	a0,0x20
    800067fe:	81e50513          	addi	a0,a0,-2018 # 80026018 <disk+0x2018>
    80006802:	ffffb097          	auipc	ra,0xffffb
    80006806:	7c6080e7          	jalr	1990(ra) # 80001fc8 <sleep>
  for(int i = 0; i < 3; i++){
    8000680a:	f9040713          	addi	a4,s0,-112
    8000680e:	84ce                	mv	s1,s3
    80006810:	bf41                	j	800067a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006812:	20058713          	addi	a4,a1,512
    80006816:	00471693          	slli	a3,a4,0x4
    8000681a:	0001d717          	auipc	a4,0x1d
    8000681e:	7e670713          	addi	a4,a4,2022 # 80024000 <disk>
    80006822:	9736                	add	a4,a4,a3
    80006824:	4685                	li	a3,1
    80006826:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000682a:	20058713          	addi	a4,a1,512
    8000682e:	00471693          	slli	a3,a4,0x4
    80006832:	0001d717          	auipc	a4,0x1d
    80006836:	7ce70713          	addi	a4,a4,1998 # 80024000 <disk>
    8000683a:	9736                	add	a4,a4,a3
    8000683c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006840:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006844:	7679                	lui	a2,0xffffe
    80006846:	963e                	add	a2,a2,a5
    80006848:	0001f697          	auipc	a3,0x1f
    8000684c:	7b868693          	addi	a3,a3,1976 # 80026000 <disk+0x2000>
    80006850:	6298                	ld	a4,0(a3)
    80006852:	9732                	add	a4,a4,a2
    80006854:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006856:	6298                	ld	a4,0(a3)
    80006858:	9732                	add	a4,a4,a2
    8000685a:	4541                	li	a0,16
    8000685c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000685e:	6298                	ld	a4,0(a3)
    80006860:	9732                	add	a4,a4,a2
    80006862:	4505                	li	a0,1
    80006864:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006868:	f9442703          	lw	a4,-108(s0)
    8000686c:	6288                	ld	a0,0(a3)
    8000686e:	962a                	add	a2,a2,a0
    80006870:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006874:	0712                	slli	a4,a4,0x4
    80006876:	6290                	ld	a2,0(a3)
    80006878:	963a                	add	a2,a2,a4
    8000687a:	05890513          	addi	a0,s2,88
    8000687e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006880:	6294                	ld	a3,0(a3)
    80006882:	96ba                	add	a3,a3,a4
    80006884:	40000613          	li	a2,1024
    80006888:	c690                	sw	a2,8(a3)
  if(write)
    8000688a:	140d0063          	beqz	s10,800069ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000688e:	0001f697          	auipc	a3,0x1f
    80006892:	7726b683          	ld	a3,1906(a3) # 80026000 <disk+0x2000>
    80006896:	96ba                	add	a3,a3,a4
    80006898:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000689c:	0001d817          	auipc	a6,0x1d
    800068a0:	76480813          	addi	a6,a6,1892 # 80024000 <disk>
    800068a4:	0001f517          	auipc	a0,0x1f
    800068a8:	75c50513          	addi	a0,a0,1884 # 80026000 <disk+0x2000>
    800068ac:	6114                	ld	a3,0(a0)
    800068ae:	96ba                	add	a3,a3,a4
    800068b0:	00c6d603          	lhu	a2,12(a3)
    800068b4:	00166613          	ori	a2,a2,1
    800068b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800068bc:	f9842683          	lw	a3,-104(s0)
    800068c0:	6110                	ld	a2,0(a0)
    800068c2:	9732                	add	a4,a4,a2
    800068c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068c8:	20058613          	addi	a2,a1,512
    800068cc:	0612                	slli	a2,a2,0x4
    800068ce:	9642                	add	a2,a2,a6
    800068d0:	577d                	li	a4,-1
    800068d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068d6:	00469713          	slli	a4,a3,0x4
    800068da:	6114                	ld	a3,0(a0)
    800068dc:	96ba                	add	a3,a3,a4
    800068de:	03078793          	addi	a5,a5,48
    800068e2:	97c2                	add	a5,a5,a6
    800068e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800068e6:	611c                	ld	a5,0(a0)
    800068e8:	97ba                	add	a5,a5,a4
    800068ea:	4685                	li	a3,1
    800068ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068ee:	611c                	ld	a5,0(a0)
    800068f0:	97ba                	add	a5,a5,a4
    800068f2:	4809                	li	a6,2
    800068f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800068f8:	611c                	ld	a5,0(a0)
    800068fa:	973e                	add	a4,a4,a5
    800068fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006900:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006904:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006908:	6518                	ld	a4,8(a0)
    8000690a:	00275783          	lhu	a5,2(a4)
    8000690e:	8b9d                	andi	a5,a5,7
    80006910:	0786                	slli	a5,a5,0x1
    80006912:	97ba                	add	a5,a5,a4
    80006914:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006918:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000691c:	6518                	ld	a4,8(a0)
    8000691e:	00275783          	lhu	a5,2(a4)
    80006922:	2785                	addiw	a5,a5,1
    80006924:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006928:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000692c:	100017b7          	lui	a5,0x10001
    80006930:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006934:	00492703          	lw	a4,4(s2)
    80006938:	4785                	li	a5,1
    8000693a:	02f71163          	bne	a4,a5,8000695c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000693e:	0001f997          	auipc	s3,0x1f
    80006942:	7ea98993          	addi	s3,s3,2026 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006946:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006948:	85ce                	mv	a1,s3
    8000694a:	854a                	mv	a0,s2
    8000694c:	ffffb097          	auipc	ra,0xffffb
    80006950:	67c080e7          	jalr	1660(ra) # 80001fc8 <sleep>
  while(b->disk == 1) {
    80006954:	00492783          	lw	a5,4(s2)
    80006958:	fe9788e3          	beq	a5,s1,80006948 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000695c:	f9042903          	lw	s2,-112(s0)
    80006960:	20090793          	addi	a5,s2,512
    80006964:	00479713          	slli	a4,a5,0x4
    80006968:	0001d797          	auipc	a5,0x1d
    8000696c:	69878793          	addi	a5,a5,1688 # 80024000 <disk>
    80006970:	97ba                	add	a5,a5,a4
    80006972:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006976:	0001f997          	auipc	s3,0x1f
    8000697a:	68a98993          	addi	s3,s3,1674 # 80026000 <disk+0x2000>
    8000697e:	00491713          	slli	a4,s2,0x4
    80006982:	0009b783          	ld	a5,0(s3)
    80006986:	97ba                	add	a5,a5,a4
    80006988:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000698c:	854a                	mv	a0,s2
    8000698e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006992:	00000097          	auipc	ra,0x0
    80006996:	bc4080e7          	jalr	-1084(ra) # 80006556 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000699a:	8885                	andi	s1,s1,1
    8000699c:	f0ed                	bnez	s1,8000697e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000699e:	0001f517          	auipc	a0,0x1f
    800069a2:	78a50513          	addi	a0,a0,1930 # 80026128 <disk+0x2128>
    800069a6:	ffffa097          	auipc	ra,0xffffa
    800069aa:	2f2080e7          	jalr	754(ra) # 80000c98 <release>
}
    800069ae:	70a6                	ld	ra,104(sp)
    800069b0:	7406                	ld	s0,96(sp)
    800069b2:	64e6                	ld	s1,88(sp)
    800069b4:	6946                	ld	s2,80(sp)
    800069b6:	69a6                	ld	s3,72(sp)
    800069b8:	6a06                	ld	s4,64(sp)
    800069ba:	7ae2                	ld	s5,56(sp)
    800069bc:	7b42                	ld	s6,48(sp)
    800069be:	7ba2                	ld	s7,40(sp)
    800069c0:	7c02                	ld	s8,32(sp)
    800069c2:	6ce2                	ld	s9,24(sp)
    800069c4:	6d42                	ld	s10,16(sp)
    800069c6:	6165                	addi	sp,sp,112
    800069c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800069ca:	0001f697          	auipc	a3,0x1f
    800069ce:	6366b683          	ld	a3,1590(a3) # 80026000 <disk+0x2000>
    800069d2:	96ba                	add	a3,a3,a4
    800069d4:	4609                	li	a2,2
    800069d6:	00c69623          	sh	a2,12(a3)
    800069da:	b5c9                	j	8000689c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069dc:	f9042583          	lw	a1,-112(s0)
    800069e0:	20058793          	addi	a5,a1,512
    800069e4:	0792                	slli	a5,a5,0x4
    800069e6:	0001d517          	auipc	a0,0x1d
    800069ea:	6c250513          	addi	a0,a0,1730 # 800240a8 <disk+0xa8>
    800069ee:	953e                	add	a0,a0,a5
  if(write)
    800069f0:	e20d11e3          	bnez	s10,80006812 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800069f4:	20058713          	addi	a4,a1,512
    800069f8:	00471693          	slli	a3,a4,0x4
    800069fc:	0001d717          	auipc	a4,0x1d
    80006a00:	60470713          	addi	a4,a4,1540 # 80024000 <disk>
    80006a04:	9736                	add	a4,a4,a3
    80006a06:	0a072423          	sw	zero,168(a4)
    80006a0a:	b505                	j	8000682a <virtio_disk_rw+0xf4>

0000000080006a0c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a0c:	1101                	addi	sp,sp,-32
    80006a0e:	ec06                	sd	ra,24(sp)
    80006a10:	e822                	sd	s0,16(sp)
    80006a12:	e426                	sd	s1,8(sp)
    80006a14:	e04a                	sd	s2,0(sp)
    80006a16:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a18:	0001f517          	auipc	a0,0x1f
    80006a1c:	71050513          	addi	a0,a0,1808 # 80026128 <disk+0x2128>
    80006a20:	ffffa097          	auipc	ra,0xffffa
    80006a24:	1c4080e7          	jalr	452(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a28:	10001737          	lui	a4,0x10001
    80006a2c:	533c                	lw	a5,96(a4)
    80006a2e:	8b8d                	andi	a5,a5,3
    80006a30:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a32:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a36:	0001f797          	auipc	a5,0x1f
    80006a3a:	5ca78793          	addi	a5,a5,1482 # 80026000 <disk+0x2000>
    80006a3e:	6b94                	ld	a3,16(a5)
    80006a40:	0207d703          	lhu	a4,32(a5)
    80006a44:	0026d783          	lhu	a5,2(a3)
    80006a48:	06f70163          	beq	a4,a5,80006aaa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a4c:	0001d917          	auipc	s2,0x1d
    80006a50:	5b490913          	addi	s2,s2,1460 # 80024000 <disk>
    80006a54:	0001f497          	auipc	s1,0x1f
    80006a58:	5ac48493          	addi	s1,s1,1452 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006a5c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a60:	6898                	ld	a4,16(s1)
    80006a62:	0204d783          	lhu	a5,32(s1)
    80006a66:	8b9d                	andi	a5,a5,7
    80006a68:	078e                	slli	a5,a5,0x3
    80006a6a:	97ba                	add	a5,a5,a4
    80006a6c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a6e:	20078713          	addi	a4,a5,512
    80006a72:	0712                	slli	a4,a4,0x4
    80006a74:	974a                	add	a4,a4,s2
    80006a76:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a7a:	e731                	bnez	a4,80006ac6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a7c:	20078793          	addi	a5,a5,512
    80006a80:	0792                	slli	a5,a5,0x4
    80006a82:	97ca                	add	a5,a5,s2
    80006a84:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a86:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a8a:	ffffb097          	auipc	ra,0xffffb
    80006a8e:	5b8080e7          	jalr	1464(ra) # 80002042 <wakeup>

    disk.used_idx += 1;
    80006a92:	0204d783          	lhu	a5,32(s1)
    80006a96:	2785                	addiw	a5,a5,1
    80006a98:	17c2                	slli	a5,a5,0x30
    80006a9a:	93c1                	srli	a5,a5,0x30
    80006a9c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006aa0:	6898                	ld	a4,16(s1)
    80006aa2:	00275703          	lhu	a4,2(a4)
    80006aa6:	faf71be3          	bne	a4,a5,80006a5c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006aaa:	0001f517          	auipc	a0,0x1f
    80006aae:	67e50513          	addi	a0,a0,1662 # 80026128 <disk+0x2128>
    80006ab2:	ffffa097          	auipc	ra,0xffffa
    80006ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>
}
    80006aba:	60e2                	ld	ra,24(sp)
    80006abc:	6442                	ld	s0,16(sp)
    80006abe:	64a2                	ld	s1,8(sp)
    80006ac0:	6902                	ld	s2,0(sp)
    80006ac2:	6105                	addi	sp,sp,32
    80006ac4:	8082                	ret
      panic("virtio_disk_intr status");
    80006ac6:	00002517          	auipc	a0,0x2
    80006aca:	d6a50513          	addi	a0,a0,-662 # 80008830 <syscalls+0x3c8>
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>

0000000080006ad6 <cas>:
    80006ad6:	100522af          	lr.w	t0,(a0)
    80006ada:	00b29563          	bne	t0,a1,80006ae4 <fail>
    80006ade:	18c5252f          	sc.w	a0,a2,(a0)
    80006ae2:	8082                	ret

0000000080006ae4 <fail>:
    80006ae4:	4505                	li	a0,1
    80006ae6:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
