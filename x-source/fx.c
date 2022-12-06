char fy();
char fx() { return fy() - 1; }
char fw() { return fx(); }

hanamake_test(fx) { hanamake_assert(fw() == 'X'); }


int plus1(int);

hanamake_test(plus1)
{
  hanamake_assert(fx() - fx());
  hanamake_assert(plus1(0) == 1);
}
