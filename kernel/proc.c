#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"



  struct proc unused_list_head;
  struct proc sleeping_list_head;
  struct proc zombie_list_head;



struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);
int global_index;



extern char trampoline[]; // trampoline.S
extern uint64 cas(volatile void *addr, int expected, int newval); // assignment 2

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}


// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;

   unused_list_head.index = -1; 
   unused_list_head.next = -1;
 
   sleeping_list_head.index = -1;
   sleeping_list_head.next = -1;
 
   zombie_list_head.index = -1;
   zombie_list_head.next = -1;
  
 struct cpu * c;
   for(c = cpus; c < &cpus[NCPU]; c++) {
   c->runnable_list_head.index=-1;
   c->runnable_list_head.next=-1;
   c->num_of_proc=__INT_MAX__; //new

     }
   


  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  int index = 0;
  global_index=0;
  for(p = proc; p < &proc[NPROC]; p++) {
      p->next = -1;                         //assignment 2
      p->index= index;
      index++;
      global_index++;
      initlock(&p->lock, "proc");
       push(&unused_list_head,p->index); //assignemnt2 
      p->kstack = KSTACK((int) (p - proc));
  }

//print_list(&unused_list_head);
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
 
  //acquire(&pid_lock);
  //assignment 2
  do{
    pid = nextpid;
  }
  while(cas(&nextpid,pid,pid+1)!=0);
  //nextpid = nextpid + 1;
  //release(&pid_lock);

  //assignment 2
  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{


  struct proc *p;

acquire(&unused_list_head.node_lock);
if(unused_list_head.next==-1){
release(&unused_list_head.node_lock);
  return 0;
}
release(&unused_list_head.node_lock);
p=&proc[unused_list_head.next];
acquire(&p->lock);
  pop(&unused_list_head);
  p->pid = allocpid();
  p->state = USED;


  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{

  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  //our add -assignment2

  remove(&zombie_list_head,p->index);

  p->next=-1;
  p->cpu_number=-1; // check?
  p->state = UNUSED;
  push(&unused_list_head,p->index);

}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{

  struct proc *p;

  p = allocproc();
  initproc = p;
  
  p->cpu_number=cpuid(); //assignment 2 - first cpu
   
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

 push(&cpus[p->cpu_number].runnable_list_head,p->index);
  release(&p->lock);

}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->cpu_number = p->cpu_number;
  np->next=-1;
  global_index++;
  np->state = RUNNABLE;
  #ifdef BLNCFLG
     int min = find_min_cpu();
    if(curr_proc->cpu_number!=min){
              increment_proc_counter(min);
            }
     push(&cpus[min].runnable_list_head,np->index);
     np->cpu_number = min;
  #else
  push(&cpus[np->cpu_number].runnable_list_head,np->index); 
  #endif

  print_state();
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{

  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  push(&zombie_list_head,p->index);

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
 
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  print_state();
    
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.

    intr_on();
     
      acquire(&c->runnable_list_head.node_lock);
      int locked=1;
      if(c->runnable_list_head.next!=-1){//assignment2 - if runnable list is not empty.
      release(&c->runnable_list_head.node_lock);
      locked=0;

      p=&proc[c->runnable_list_head.next];
       acquire(&p->lock);
      pop(&c->runnable_list_head);
     

      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.

         p->cpu_number= cpuid();//assignment2 - need to check.
        p->state = RUNNING;
        c->proc = p;

        swtch(&c->context, &p->context);
       
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
      }
      #ifdef BLNCFLG
      else{
        int stilling = still_proc();
        if(stilling!=-1){
          release( &c->runnable_list_head.node_lock);
          locked=0;
          increment_proc_counter(cpuid());
          p = &proc[stilling];
          acquire(&p->lock);
         // pop(&c->runnable_list_head);
     

      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.

        p->cpu_number= cpuid();//assignment2 - need to check.
        p->state = RUNNING;
        c->proc = p;

        swtch(&c->context, &p->context);
       
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);

        }
        
      }
      #endif
      if(locked==1)
      release( &c->runnable_list_head.node_lock);
  
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);

  // assignment2
  struct cpu *c = mycpu(); 
    p->state = RUNNABLE;
  
   push(&c->runnable_list_head,p->index);
  

  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  p->cpu_number=cpuid();
  
  push(&sleeping_list_head,p->index);
    
  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.



// Wake up all processes sleeping on chan.
// Must be called without any p->lock.


void
wakeup(void *chan)
{
    struct proc *pred_proc = &sleeping_list_head; 
    acquire(&pred_proc->node_lock);
     
    if (pred_proc->next != -1){
      struct proc* curr_proc= &proc[pred_proc->next];
     acquire(&curr_proc->node_lock);
      while (curr_proc->next!=-1 ){
        int next_index = curr_proc->next;
        if(curr_proc!= myproc()) {
          acquire(&curr_proc->lock);
          if(curr_proc->state == SLEEPING && curr_proc->chan==chan){
            pred_proc->next=curr_proc->next;
            curr_proc->next=-1;
            curr_proc->state = RUNNABLE;
             #ifdef BLNCFLG
            int min = find_min_cpu();
            if(curr_proc->cpu_number!=min){
              increment_proc_counter(min);
            }
              push(&cpus[min].runnable_list_head,curr_proc->index);
              curr_proc->cpu_number = min;
            #else
            push(&cpus[curr_proc->cpu_number].runnable_list_head,curr_proc->index); 
            #endif
            release(&curr_proc->lock);
            release(&curr_proc->node_lock);
            curr_proc= &proc[next_index];
            acquire(&curr_proc->node_lock);

          }
          else{
            release(&pred_proc->node_lock);
            pred_proc = curr_proc;
            release(&curr_proc->lock);
          curr_proc = &proc[curr_proc->next];
          acquire(&curr_proc->node_lock);
           
          }
        
        }
        else{
          release(&pred_proc->node_lock);
            pred_proc = curr_proc;
          curr_proc = &proc[curr_proc->next];
          acquire(&curr_proc->node_lock);
          
        }
          
      }
    if(curr_proc!= myproc()){

      acquire(&curr_proc->lock);
    if(curr_proc->chan==chan){
          pred_proc->next=curr_proc->next;
          curr_proc->next=-1;
      curr_proc->state = RUNNABLE;
         #ifdef BLNCFLG
            int min = find_min_cpu();
            if(curr_proc->cpu_number!=min){
              increment_proc_counter(min);
            }
              push(&cpus[min].runnable_list_head,curr_proc->index);
              curr_proc->cpu_number = min;
            #else
            push(&cpus[curr_proc->cpu_number].runnable_list_head,curr_proc->index); 
            #endif

    }
      release(&curr_proc->lock);
     
      
    }
    release(&curr_proc->node_lock);
 
  }
  release(&pred_proc->node_lock);

}



// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{

  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        remove(&sleeping_list_head,p->index);
        p->state = RUNNABLE;
        push(&cpus[p->cpu_number].runnable_list_head,p->index);   
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

//assignment 2
extern void push(struct proc* list_empty_head, int index){
    struct proc *pred_proc = list_empty_head;
    acquire(&pred_proc->node_lock);
      if (list_empty_head->next != -1){
    struct proc* curr_proc= &proc[pred_proc->next]; 
    acquire(&curr_proc->node_lock); 
    while (pred_proc->next!=-1 ){
     
        release(&pred_proc->node_lock);
        pred_proc = curr_proc;
        curr_proc = &proc[curr_proc->next];
        acquire(&curr_proc->node_lock); 
  }
 
  release(&curr_proc->node_lock);
  
  }
    pred_proc->next = index;
  release(&pred_proc->node_lock);
   
}

//assignment 2
extern void pop(struct proc *list_empty_head){
   acquire(&list_empty_head->node_lock);
  if(list_empty_head->next != -1){ // if list is not empty
    struct proc *curr_proc = &proc[list_empty_head->next];
    acquire(&curr_proc->node_lock);
    if(curr_proc->next!=-1){
      int next_index= curr_proc->next;
    list_empty_head->next = next_index;//next_proc->index;
    }
    else{
      list_empty_head->next=-1;
    }
    curr_proc->next = -1;
    release(&curr_proc->node_lock);
  }
  release(&list_empty_head->node_lock);
}


extern void print_state(){
  //print_list(&unused_list_head);
  // printf("sleeping list : ");
  // print_list(&sleeping_list_head);
  // //print_list(&zombie_list_head);
  // if(sleeping_list_head.next!=-1)
  // printf("sleeping head pid : %d\n",proc[sleeping_list_head.next].pid);
  //   printf("runnable list : ");
  // print_list(&mycpu()->runnable_list_head);
  // printf("\n");
}


extern void print_list(struct proc* list_empty_head){
  struct proc* curr_proc = list_empty_head;
    acquire(&curr_proc->node_lock);
    struct proc* next_proc= &proc[curr_proc->next]; 
    acquire(&next_proc->node_lock);   
    while (curr_proc->next != -1){
      printf("[ %d : %d ] ->", curr_proc->index, curr_proc->next);
      
        release(&curr_proc->node_lock);
        curr_proc = &proc[curr_proc->next];
        next_proc = &proc[curr_proc->next];
        acquire(&next_proc->node_lock);

  }
  printf("[ %d : %d ] ->\n", curr_proc->index, curr_proc->next);
 
  release(&next_proc->node_lock);
  release(&curr_proc->node_lock);
  
}




extern void remove(struct proc* list_empty_head, int index){
  if (list_empty_head->next != -1){
    struct proc *pred_proc = list_empty_head;
    acquire(&pred_proc->node_lock);
    
    struct proc* curr_proc= &proc[pred_proc->next]; 
    acquire(&curr_proc->node_lock); 
    while (curr_proc->next!=-1 ){
      if(curr_proc->index==index){
        
         
          pred_proc->next=curr_proc->next;
          curr_proc->next=-1;
          release(&curr_proc->node_lock);
          release(&pred_proc->node_lock);
          return;
      }
      
        release(&pred_proc->node_lock);
        pred_proc = curr_proc;
        curr_proc = &proc[curr_proc->next];
        acquire(&curr_proc->node_lock); 

  }
  if(curr_proc->index==index){
  pred_proc->next = -1;
  }
  release(&curr_proc->node_lock);
  release(&pred_proc->node_lock);
  }


}

//assignment2 
int set_cpu(int cpu_num){
  // struct proc* p = myproc();
  // yield();
  // p->cpu_number = cpu_num;
return 0;
}

int get_cpu(){
  return cpuid();
}

//assignment2 
int cpu_process_count(int cpu_num){
  int ret = cpus[cpu_num].num_of_proc;
  return ret;
}

//assignment2

struct cpu* find_min_cpu(){
  struct cpu* c;
  uint64 min_procs= __INT_MAX__;
  struct cpu* c_min;
  for(c_min = cpus ,c = cpus; c < &cpus[NCPU]; c++){
    if(c->num_of_proc < min_procs){
      min_procs = c->num_of_proc;
      c_min= c;
    }
      
  }
  return c_min;

}

int increment_proc_counter(int cpu_num){
  int proc_counter;
  //assignment 2
  do{
    proc_counter = cpus[cpu_num].num_of_proc;
  }
  while(cas(&cpus[cpu_num].num_of_proc,proc_counter,proc_counter+1)!=0);
  return proc_counter;

}

int still_proc(){

int ret;
struct cpu * c;

for(c = cpus; c < &cpus[NCPU]; c++){
  acquire(&c->runnable_list_head.node_lock);
  if(c->runnable_list_head.next!=-1){
    acquire(&proc[c->runnable_list_head.next].node_lock);
    ret = c->runnable_list_head.next;
     if(proc[ret].next!=-1){
      int next_index= proc[ret].next;
    c->runnable_list_head.next = next_index;//next_proc->index;
    }
    else{
      c->runnable_list_head.next=-1;
    }
    
    release(&proc[ret].node_lock);
    release(&c->runnable_list_head.node_lock);
   // pop(&c->runnable_list_head);
    return ret;
  }
}
release(&c->runnable_list_head.node_lock);
return -1;

}

