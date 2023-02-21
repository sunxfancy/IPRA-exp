// This is my previous open source project, should go into third_party

#include <pwd.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <chrono>
#include <cstdio>
#include <deque>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

using namespace std;

struct Job {
  Job(pid_t pid, std::string name, std::string user) {
    this->pid = pid;
    this->name = name;
    this->user = user;
  }

  Job(const Job& other) {
    pid = other.pid;
    name = other.name;
    user = other.user;
  }

  pid_t pid;
  std::string name;
  std::string user;
};

class Submit {
 public:
  Submit();
  ~Submit();

  /**
   * submit a job, if something is running, change the queue file and waiting
   * it.
   */
  void sub(int argc, char** argv);

  /**
   * show the task queue
   */
  void show();

  bool checkAndAddCfg(const char* command);
  void removeFirstInCfg();
  void setupSignal();
  FILE* rfp;

 private:
  void createNewProcess(int argc, char** argv);
  void loadCfg();
  void loadCfg(FILE* fp);
  void saveCfg(FILE* fp);
  const char* getUserName();

  pid_t my_pid;
  std::deque<Job> job_queue;
};

Submit::Submit() { my_pid = getpid(); }

Submit::~Submit() {}

static Submit* object;

void sig_handler(int signo) {
  if (signo == SIGINT) {
    object->removeFirstInCfg();
    flock(object->rfp->_fileno, LOCK_UN);
    fclose(object->rfp);
    exit(0);
  }
}

void Submit::setupSignal() {
  object = this;
  signal(SIGINT, sig_handler);
}

void Submit::sub(int argc, char** argv) {
  pid_t last_pid = 0;
  rfp = fopen("/tmp/submit_running.lock", "w+");
  if (flock(rfp->_fileno, LOCK_EX | LOCK_NB) == -1) {
    if (errno == EWOULDBLOCK) {
      // lock file was locked, something running
      if (checkAndAddCfg(argv[0])) {
        setupSignal();
        flock(rfp->_fileno,
              LOCK_EX);  // first lock, means the next will be this one
        goto BEGIN_WORKING;
      } else {
        setupSignal();
        flock(rfp->_fileno, LOCK_EX);
        goto STILL_WAITING;
      }
    } else {
      // error
      printf("inner error\n");
    }
  } else {
    // flock(rfp->_fileno, LOCK_UN);
    // lock file was unlocked, nothing running or just switch programs
    if (checkAndAddCfg(argv[0])) {
      setupSignal();
      goto BEGIN_WORKING;
    } else {
      setupSignal();
      goto STILL_WAITING;
    }
  }

STILL_WAITING:
  loadCfg();
  if (job_queue.front().pid == my_pid) goto BEGIN_WORKING;

  if (job_queue.front().pid == last_pid) removeFirstInCfg();
  last_pid = job_queue.front().pid;

  flock(rfp->_fileno, LOCK_UN);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
  flock(rfp->_fileno, LOCK_EX);
  goto STILL_WAITING;

BEGIN_WORKING:
  createNewProcess(argc, argv);
  // remove first line
  removeFirstInCfg();
  flock(rfp->_fileno, LOCK_UN);
  fclose(rfp);
}

void Submit::createNewProcess(int argc, char** argv) {
  pid_t pid = fork();  //   父进程返回的pid是大于零的，而创建的子进程返回的pid是
                       //   等于0的，这个机制正好用来区分 父进程和子进程
  if (pid == 0)  // 子进程
  {
    int ret = execvp(argv[0], argv);
    exit(ret);  // 子进程加载异常，否则这句代码应该在加载后被覆盖
  } else  // 父进程
  {
    int status;
    pid_t ret;
    ret = wait(&status);
    if (ret < 0) {
      perror("wait error");
      exit(EXIT_FAILURE);
    }
    if (WIFEXITED(status))
      printf("work complete\n");
    else if (WIFSIGNALED(status))
      printf("child exited abnormal signal number=%d\n", WTERMSIG(status));
    else if (WIFSTOPPED(status))
      printf("child stoped signal number=%d\n", WSTOPSIG(status));
  }
}

void Submit::show() {
  loadCfg();
  if (job_queue.empty()) {
    printf("Now, the job queue is empty.\n");
  }
  for (auto p : job_queue) {
    cout << p.pid << "\t\t\t" << p.name << "\t\t" << p.user << endl;
  }
}

void Submit::loadCfg() {
  FILE* fp = fopen("/tmp/submit_jobqueue.lock",
                   "w+");       // open lock file, if not exist, then create one
  flock(fp->_fileno, LOCK_EX);  // lock

  FILE* frp = fopen("/tmp/submit_jobqueue", "r");
  if (frp != NULL) {
    loadCfg(frp);
    fclose(frp);
  }

  flock(fp->_fileno, LOCK_UN);  // unlock
  fclose(fp);                   // release file
}

void Submit::loadCfg(FILE* fp) {
  job_queue.clear();

  char cmd[256];
  char user[64];
  pid_t pid;
  while (fscanf(fp, "%d %s %s", &pid, cmd, user) != EOF) {
    Job job{pid, string(cmd), string(user)};
    job_queue.push_back(job);
  }
}

void Submit::saveCfg(FILE* fp) {
  for (const Job& p : job_queue) {
    fprintf(fp, "%d %s %s\n", p.pid, p.name.c_str(), p.user.c_str());
  }
  fprintf(fp, "\n");
}

// return true means queue empty
bool Submit::checkAndAddCfg(const char* command) {
  bool ret;
  FILE* fp = fopen("/tmp/submit_jobqueue.lock", "w+");
  flock(fp->_fileno, LOCK_EX);

  FILE* frp = fopen("/tmp/submit_jobqueue", "r");
  if (frp != NULL) {
    loadCfg(frp);
    fclose(frp);
  }

  if (job_queue.empty())
    ret = true;
  else
    ret = false;

  Job job{my_pid, string(command), string(getUserName())};
  job_queue.push_back(job);

  FILE* fwp = fopen("/tmp/submit_jobqueue", "w");
  saveCfg(fwp);
  fclose(fwp);

  flock(fp->_fileno, LOCK_UN);
  fclose(fp);
  return ret;
}

void Submit::removeFirstInCfg() {
  FILE* fp = fopen("/tmp/submit_jobqueue.lock", "w+");
  flock(fp->_fileno, LOCK_EX);

  FILE* frp = fopen("/tmp/submit_jobqueue", "r");
  if (frp != NULL) {
    loadCfg(frp);
    fclose(frp);
  }

  if (!job_queue.empty()) job_queue.pop_front();
  FILE* fwp = fopen("/tmp/submit_jobqueue", "w");
  saveCfg(fwp);
  fclose(fwp);

  flock(fp->_fileno, LOCK_UN);  // 释放文件锁
  fclose(fp);
}

const char* Submit::getUserName() {
  uid_t uid = geteuid();
  struct passwd* pw = getpwuid(uid);
  if (pw) return pw->pw_name;
  return "";
}

const char* help_msg =
    "Submit \n"
    "Usage:\tsub [options] executable [args...]\n\n"
    "\t--show / -s\t\t\tShow task queue\n"
    "\t--help / -h / -?\t\tPring help message\n";

int main(int argc, char* argv[]) {
  Submit submit;

  if (argc <= 1) {
    printf("%s", help_msg);
    return 0;
  }

  string arg1 = argv[1];
  if (arg1 == "-s" || arg1 == "--show") {
    submit.show();
    return 0;
  }

  if (arg1 == "-h" || arg1 == "-?" || arg1 == "--help") {
    printf("%s", help_msg);
    return 0;
  }

  if (arg1[0] == '-') {
    printf("%s", help_msg);
    return 0;
  }

  submit.sub(argc - 1, argv + 1);

  return 0;
}
