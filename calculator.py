import math


def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    if a == 0 or b == 0:
        return 0
    return a * b


def divide(a, b):
    if b == 0:
        raise ValueError("division by zero")
    return a / b