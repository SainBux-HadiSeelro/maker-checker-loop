import unittest
import math

from calculator import add, subtract, multiply, divide


class TestCalculator(unittest.TestCase):

    def test_add_floats(self):
        self.assertAlmostEqual(add(0.1, 0.2), 0.3)

    def test_multiply_with_zero(self):
        self.assertEqual(multiply(0, 5), 0)
        self.assertEqual(multiply(5, 0), 0)

    def test_divide_by_zero(self):
        with self.assertRaises(ValueError):
            divide(10, 0)

    def test_divide_normal(self):
        self.assertEqual(divide(10, 2), 5.0)


if __name__ == "__main__":
    unittest.main()