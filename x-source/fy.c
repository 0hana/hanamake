char fz();
char fy() { return fz() - 1; }

hanamake_test(fy) { hanamake_assert(fy() == 'Y'); }
