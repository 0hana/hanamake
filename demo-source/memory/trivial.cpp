namespace ns_test {
	int functionA(int X, char Y) { return X + Y; }
}

extern "C" int plus1(int A) { return A + 1; }  // test is in x-source/fx.c

hanamake_test(ns_test::functionA(int, char))
{
  hanamake_assert(ns_test::functionA(10, 'A') == 75);
  hanamake_assert(ns_test::functionA(10, 'B') == 76);
  hanamake_assert(ns_test::functionA(10, 'C') == 77);
  hanamake_assert(ns_test::functionA(10, 'D') == 78);
  hanamake_assert(ns_test::functionA(10, 'E') == 79);
  hanamake_assert(ns_test::functionA(10, 'F') == 80);
}
