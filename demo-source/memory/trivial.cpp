namespace NS_test {
	int functionA(int X, char Y) { return X + Y; }
}


hanamake_test(NS_test::functionA(int, char))
{
  hanamake_assert(NS_test::functionA(10, 'A') == 75);
  hanamake_assert(NS_test::functionA(10, 'B') == 76);
  hanamake_assert(NS_test::functionA(10, 'C') == 77);
  hanamake_assert(NS_test::functionA(10, 'D') == 78);
  hanamake_assert(NS_test::functionA(10, 'E') == 79);
  hanamake_assert(NS_test::functionA(10, 'F') == 80);
}
