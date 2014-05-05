# -*- perl -*-

use strict;
use warnings;
use Test::Simple tests => 24;
use Math::Palindrome ':all';


ok(next_palindrome(1) == 2);
ok(next_palindrome(2) == 3);
ok(next_palindrome(3) == 4);
ok(next_palindrome(4) == 5);
ok(next_palindrome(5) == 6);
ok(next_palindrome(6) == 7);
ok(next_palindrome(7) == 8);
ok(next_palindrome(8) == 9);
ok(!next_palindrome(9) != 11);
ok(next_palindrome(9) == 11);
ok(next_palindrome(10) == 11);
ok(!next_palindrome(11) != 22);
ok(next_palindrome(11) == 22);
ok(next_palindrome(22) == 33);
ok(next_palindrome(33) == 44);
ok(next_palindrome(44) == 55);
ok(next_palindrome(55) == 66);
ok(next_palindrome(66) == 77);
ok(next_palindrome(77) == 88);
ok(next_palindrome(88) == 99);
ok(!next_palindrome(99) != 101);
ok(next_palindrome(99) == 101);
ok(!next_palindrome(999) != 1001);
ok(next_palindrome(999) == 1001);
