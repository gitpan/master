# -*- perl -*-

use strict;
use warnings;
use Test::Simple tests => 34;
use Math::Palindrome ':all';


ok(previous_palindrome(1000) == 999);
ok(previous_palindrome(999) == 989);
ok(previous_palindrome(111) == 101);
ok(previous_palindrome(101) == 99);
ok(previous_palindrome(99) == 88);
ok(previous_palindrome(88) == 77);
ok(previous_palindrome(30) == 22);
ok(previous_palindrome(22) == 11);
ok(previous_palindrome(11) == 9);
ok(previous_palindrome(9) == 8);
ok(previous_palindrome(8) == 7);
ok(previous_palindrome(7) == 6);
ok(previous_palindrome(6) == 5);
ok(previous_palindrome(5) == 4);
ok(previous_palindrome(4) == 3);
ok(previous_palindrome(3) == 2);
ok(previous_palindrome(2) == 1);
ok(!previous_palindrome(1000) != 999);
ok(!previous_palindrome(999) != 989);
ok(!previous_palindrome(111) != 101);
ok(!previous_palindrome(101) != 99);
ok(!previous_palindrome(99) != 88);
ok(!previous_palindrome(88) != 77);
ok(!previous_palindrome(30) != 22);
ok(!previous_palindrome(22) != 11);
ok(!previous_palindrome(11) != 9);
ok(!previous_palindrome(9) != 8);
ok(!previous_palindrome(8) != 7);
ok(!previous_palindrome(7) != 6);
ok(!previous_palindrome(6) != 5);
ok(!previous_palindrome(5) != 4);
ok(!previous_palindrome(4) != 3);
ok(!previous_palindrome(3) != 2);
ok(!previous_palindrome(2) != 1);!
