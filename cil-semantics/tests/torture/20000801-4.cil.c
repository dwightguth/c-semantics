/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

extern  __attribute__((__nothrow__, __noreturn__)) void abort(void)  __attribute__((__leaf__)) ;
extern  __attribute__((__nothrow__, __noreturn__)) void exit(int __status )  __attribute__((__leaf__)) ;
int foo(void) 
{ char s[2] ;

  {
  s[0] = (char )'\000';
  s[1] = (char)0;
  return (0 == (int )s[1]);
}
}
char *t  ;
int main(void) 
{ char s[2] ;
  int tmp ;

  {
  s[0] = (char )'x';
  s[1] = (char )'\000';
  t = s;
  tmp = foo();
  if (tmp) {
    exit(0);
  } else {
    abort();
  }
}
}