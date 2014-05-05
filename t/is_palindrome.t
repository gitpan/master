# -*- perl -*-

use strict;
use warnings;
use Test::Simple tests => 27;
use Math::Palindrome 'is_palindrome';


ok(is_palindrome(1));
ok(is_palindrome(2));
ok(is_palindrome(3));
ok(is_palindrome(4));
ok(is_palindrome(5));
ok(is_palindrome(6));
ok(is_palindrome(7));
ok(is_palindrome(8));
ok(is_palindrome(9));
ok(!is_palindrome(10));
ok(is_palindrome(11));
ok(is_palindrome(22));
ok(is_palindrome(33));
ok(is_palindrome(44));
ok(is_palindrome(55));
ok(is_palindrome(66));
ok(!is_palindrome(77));
ok(is_palindrome(88));
ok(is_palindrome(99));
ok(!is_palindrome(100));
ok(is_palindrome(101));
ok(!is_palindrome(1000));
ok(is_palindrome(1001));
ok(!is_palindrome(10000));
ok(is_palindrome(10001));
ok(is_palindrome(100000));
ok(is_palindrome(100001));
