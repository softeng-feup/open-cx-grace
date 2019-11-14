#include "ros/ros.h"
#include <geometry_msgs/Twist.h>

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <unistd.h>
#include <termios.h>
#include <signal.h>
#include <arpa/inet.h>
#include <stdarg.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <netdb.h>
#include <map>

#define MAXLINE 4096
#define PORT 8080
#define SA struct sockaddr

int alarm_flag = 0;

/*
Luís Sousa - lm.sousa@fe.up.pt / lm.sousa@ieee.org
IEEE UP SB - nuieee@fe.up.pt
*/

// Map for movement keys
std::map<char, std::vector<float>> moveBindings{
    {'i', {1, 0, 0, 0}},
    {'o', {1, 0, 0, -1}},
    {'j', {0, 0, 0, 1}},
    {'l', {0, 0, 0, -1}},
    {'u', {1, 0, 0, 1}},
    {',', {-1, 0, 0, 0}},
    {'.', {-1, 0, 0, 1}},
    {'m', {-1, 0, 0, -1}},
    {'O', {1, -1, 0, 0}},
    {'I', {1, 0, 0, 0}},
    {'J', {0, 1, 0, 0}},
    {'L', {0, -1, 0, 0}},
    {'U', {1, 1, 0, 0}},
    {'<', {-1, 0, 0, 0}},
    {'>', {-1, -1, 0, 0}},
    {'M', {-1, 1, 0, 0}},
    {'t', {0, 0, 1, 0}},
    {'b', {0, 0, -1, 0}},
    {'k', {0, 0, 0, 0}},
    {'K', {0, 0, 0, 0}}};

std::map<char, std::vector<float>> speedBindings{
    {'q', {1.1, 1.1}},
    {'z', {0.9, 0.9}},
    {'w', {1.1, 1}},
    {'x', {0.9, 1}},
    {'e', {1, 1.1}},
    {'c', {1, 0.9}}};

// Reminder message
const char *msg = R"(

Reading from the keyboard and Publishing to Twist!
---------------------------
Moving around:
   u    i    o
   j    k    l
   m    ,    .

For Holonomic mode (strafing), hold down the shift key:
---------------------------
   U    I    O
   J    K    L
   M    <    >

t : up (+z)
b : down (-z)

anything else : stop

q/z : increase/decrease max speeds by 10%
w/x : increase/decrease only linear speed by 10%
e/c : increase/decrease only angular speed by 10%

CTRL-C to quit

)";

// Init variables
float speed(0.5);              // Linear velocity (m/s)
float turn(1.0);               // Angular velocity (rad/s)
float x(0), y(0), z(0), th(0); // Forward/backward/neutral direction vars
char key(' ');

ros::Publisher pub;
geometry_msgs::Twist twist;

int getch(void)
{
  int ch;
  struct termios oldt;
  struct termios newt;

  // Store old settings, and copy to new settings
  tcgetattr(STDIN_FILENO, &oldt);
  newt = oldt;

  // Make required changes and apply the settings
  newt.c_lflag &= ~(ICANON | ECHO);
  newt.c_iflag |= IGNBRK;
  newt.c_iflag &= ~(INLCR | ICRNL | IXON | IXOFF);
  newt.c_lflag &= ~(ICANON | ECHO | ECHOK | ECHOE | ECHONL | ISIG | IEXTEN);
  newt.c_cc[VMIN] = 1;
  newt.c_cc[VTIME] = 0;
  tcsetattr(fileno(stdin), TCSANOW, &newt);

  // Get the current character
  ch = getchar();

  // Reapply old settings
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);

  return ch;
}

void publish_vel()
{
  // If the key corresponds to a key in moveBindings
  if (moveBindings.count(key) == 1)
  {
    // Grab the direction data
    x = moveBindings[key][0];
    y = moveBindings[key][1];
    z = moveBindings[key][2];
    th = moveBindings[key][3];

    printf("\rCurrent: speed %f\tturn %f | Last command: %c   ", speed, turn, key);
  }

  // Otherwise if it corresponds to a key in speedBindings
  else if (speedBindings.count(key) == 1)
  {
    // Grab the speed data
    speed = speed * speedBindings[key][0];
    //turn = turn * speedBindings[key][1];

    printf("\rCurrent: speed %f\tturn %f | Last command: %c   ", speed, turn, key);
  }

  // Otherwise, set the robot to stop
  else
  {
    x = 0;
    y = 0;
    z = 0;
    th = 0;

    // If ctrl-C (^C) was pressed, terminate the program
    if (key == '\x03')
    {
      exit(0);
    }

    printf("\rCurrent: speed %f\tturn %f | Invalid command! %c", speed, turn, key);
  }

  // Update the Twist message
  twist.linear.x = x * speed;
  twist.linear.y = y * speed;
  twist.linear.z = z * speed;

  twist.angular.x = 0;
  twist.angular.y = 0;
  twist.angular.z = th * turn;

  // Publish it and resolve any remaining callbacks
  pub.publish(twist);
  ros::spinOnce();
}

void emergency_brakes(int i)
{
  printf("Key was %c %d\n", key, i);
  key = 'k';
  printf("Key is %c %d\n", key, i);
  publish_vel();
  exit(1);
}

int main(int argc, char **argv)
{

  (void)signal(SIGINT, emergency_brakes);

  ros::init(argc, argv, "keyboard_listener");
  ros::NodeHandle n;

  pub = n.advertise<geometry_msgs::Twist>("cmd_vel", 1);
  //printf("%s", msg);
  //printf("\rCurrent: speed %f\tturn %f | Awaiting command...\r", speed, turn);

  int server_fd, new_socket, valread;
  struct sockaddr_in address;
  int opt = 1;
  int addrlen = sizeof(address);
  char buffer[255];
  //std::string vang;
  //char *hello = "Hello from server";

  // Creating socket file descriptor
  if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
  {
    perror("socket failed");
    exit(EXIT_FAILURE);
  }

  // Forcefully attaching socket to the port 8080
  if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT,
                 &opt, sizeof(opt)))
  {
    perror("setsockopt");
    exit(EXIT_FAILURE);
  }
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = INADDR_ANY;
  address.sin_port = htons(PORT);

  // Forcefully attaching socket to the port 8080
  if (bind(server_fd, (struct sockaddr *)&address,
           sizeof(address)) < 0)
  {
    perror("bind failed");
    exit(EXIT_FAILURE);
  }
  if (listen(server_fd, 3) < 0)
  {
    perror("listen");
    exit(EXIT_FAILURE);
  }

  while ((new_socket = accept(server_fd, (struct sockaddr *)&address,
                              (socklen_t *)&addrlen)) < 0)
  {
  }
  while (true)
  {
    valread = read(new_socket, buffer, 7);
    if (valread == 6)
    {
      key = buffer[0];//vang.at(0);
      if (key != 'k')
      {
        turn = (buffer[3] - '0') * 0.1; //(vang.at(3) - '0') * 0.1;
        turn += (buffer[4] - '0') * 0.01; //(vang.at(4) - '0') * 0.01;
        turn += (buffer[5] - '0')* 0.001; //(vang.at(5) - '0') * 0.001;
      }
      else
      {
        turn = 0;
      }
      printf("\n*%s*\n", buffer);
      publish_vel();
    }
    else{
      key ='k';
      publish_vel();
    }
    
  }

  /*while (true)
  {
    // Get the pressed key
    printf("key: %c *\n", key);
    key = getch();
    alarm(3);
    publish_vel();
  }*/

  return 0;
}
