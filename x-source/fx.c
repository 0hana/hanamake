char fy();
char fx() { return fy() - 1; }

hanamake_test(fx) { hanamake_assert(fx() == 'X'); }
