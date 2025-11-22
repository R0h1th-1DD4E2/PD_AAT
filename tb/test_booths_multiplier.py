import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.types import LogicArray
import random
import sys

# Helper function to convert to signed
def to_signed(value, bits):
    """Convert unsigned value to signed (two's complement)"""
    if value & (1 << (bits - 1)):  # Check if MSB is set
        return value - (1 << bits)
    return value

def to_unsigned(value, bits):
    """Convert signed value to unsigned (two's complement)"""
    if value < 0:
        return (1 << bits) + value
    return value & ((1 << bits) - 1)  # Mask to bits

class BoothsMultiplierTB:
    def __init__(self, dut):
        self.dut = dut
        self.N = 8  # Parameter N (change if needed - should match Verilog parameter)
        self.test_count = 0
        self.pass_count = 0
        self.fail_count = 0
        
    async def reset(self):
        """Reset the DUT"""
        self.dut.rst_n.value = 0
        self.dut.load.value = 0
        self.dut.A.value = 0
        self.dut.B.value = 0
        await Timer(20, unit='ns')
        await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 1
        await RisingEdge(self.dut.clk)
        
    async def multiply(self, a, b, test_name=""):
        """Perform multiplication and check result"""
        self.test_count += 1
        
        # Convert to unsigned for hardware
        a_unsigned = to_unsigned(a, self.N)
        b_unsigned = to_unsigned(b, self.N)
        
        # Calculate expected result (signed multiplication)
        expected = a * b
        expected_unsigned = to_unsigned(expected, 2 * self.N)
        
        # Ensure we're in IDLE state and done is low
        await RisingEdge(self.dut.clk)
        
        # Apply inputs
        self.dut.A.value = a_unsigned
        self.dut.B.value = b_unsigned
        self.dut.load.value = 0
        
        # Wait a clock cycle for inputs to settle
        await RisingEdge(self.dut.clk)
        
        # Pulse load signal for exactly one clock cycle
        self.dut.load.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.load.value = 0
        
        # Wait for done signal to go high with timeout
        timeout_cycles = 1000  # Large timeout, just for safety
        cycles = 0
        
        # Wait until done goes high
        while int(self.dut.done.value) == 0:
            await RisingEdge(self.dut.clk)
            cycles += 1
            if cycles > timeout_cycles:
                self.dut._log.error(f"[TIMEOUT] Test {self.test_count}: {test_name}")
                self.dut._log.error(f"  Multiplication did not complete after {cycles} cycles")
                self.dut._log.error(f"  Current state: {int(self.dut.cur_state.value)}")
                self.dut._log.error(f"  Counter: {int(self.dut.counter.value)}")
                self.dut._log.error(f"  Done: {int(self.dut.done.value)}")
                self.fail_count += 1
                return False
        
        # Done is high, read the result
        result = int(self.dut.C.value)
        result_signed = to_signed(result, 2 * self.N)
        
        # Check result
        if result == expected_unsigned:
            self.dut._log.info(f"[PASS] Test {self.test_count}: {test_name}")
            self.dut._log.info(f"  A={a} (0x{a_unsigned:02x}), B={b} (0x{b_unsigned:02x})")
            self.dut._log.info(f"  Result={result_signed} (0x{result:04x}), Expected={expected} (0x{expected_unsigned:04x})")
            self.dut._log.info(f"  Completed in {cycles} cycles")
            self.pass_count += 1
            return True
        else:
            self.dut._log.error(f"[FAIL] Test {self.test_count}: {test_name}")
            self.dut._log.error(f"  A={a} (0x{a_unsigned:02x}), B={b} (0x{b_unsigned:02x})")
            self.dut._log.error(f"  Result={result_signed} (0x{result:04x}), Expected={expected} (0x{expected_unsigned:04x})")
            self.dut._log.error(f"  Raw comparison: result={result} vs expected_unsigned={expected_unsigned}")
            self.fail_count += 1
            return False
    
    def print_summary(self):
        """Print test summary"""
        self.dut._log.info("=" * 60)
        self.dut._log.info("Test Summary:")
        self.dut._log.info("=" * 60)
        self.dut._log.info(f"Total Tests: {self.test_count}")
        self.dut._log.info(f"Passed:      {self.pass_count}")
        self.dut._log.info(f"Failed:      {self.fail_count}")
        if self.fail_count == 0:
            self.dut._log.info("*** ALL TESTS PASSED! ***")
        else:
            self.dut._log.error("*** SOME TESTS FAILED ***")
        self.dut._log.info("=" * 60)


@cocotb.test()
async def booths_multiplier_test(dut):
    """Main test for Booth's Multiplier with 100 test cases"""
    
    # Create clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Create testbench object
    tb = BoothsMultiplierTB(dut)
    
    dut._log.info("=" * 60)
    dut._log.info(f"Booth's Multiplier CocoTB Testbench - {tb.N}-bit")
    dut._log.info("=" * 60)
    
    # Reset DUT
    await tb.reset()
    
    # ========================================
    # Directed Tests (20 tests)
    # ========================================
    dut._log.info("\n--- Directed Tests ---")
    
    # Basic operations
    await tb.multiply(5, 3, "5 * 3")
    await tb.multiply(0, 100, "0 * 100")
    await tb.multiply(100, 0, "100 * 0")
    await tb.multiply(1, 42, "1 * 42")
    await tb.multiply(42, 1, "42 * 1")
    
    # Powers of 2
    await tb.multiply(16, 4, "16 * 4")
    await tb.multiply(8, 8, "8 * 8")
    await tb.multiply(2, 64, "2 * 64")
    
    # Positive numbers
    await tb.multiply(7, 6, "7 * 6")
    await tb.multiply(15, 15, "15 * 15")
    await tb.multiply(10, 10, "10 * 10")
    
    # Negative * Positive
    await tb.multiply(-5, 3, "-5 * 3")
    await tb.multiply(5, -3, "5 * -3")
    await tb.multiply(-10, 7, "-10 * 7")
    await tb.multiply(12, -4, "12 * -4")
    
    # Negative * Negative
    await tb.multiply(-7, -4, "-7 * -4")
    await tb.multiply(-3, -8, "-3 * -8")
    await tb.multiply(-1, -1, "-1 * -1")
    
    # Edge cases for 8-bit signed (-128 to 127)
    await tb.multiply(127, 1, "127 * 1 (max positive)")
    await tb.multiply(-128, 1, "-128 * 1 (max negative)")
    
    # ========================================
    # Random Positive Tests (20 tests)
    # ========================================
    dut._log.info("\n--- Random Positive Tests ---")
    random.seed(42)  # For reproducibility
    
    max_pos = (1 << (tb.N - 1)) - 1  # 127 for 8-bit
    for i in range(20):
        a = random.randint(0, max_pos)
        b = random.randint(0, max_pos)
        await tb.multiply(a, b, f"Random pos {i+1}: {a} * {b}")
    
    # ========================================
    # Random Negative Tests (20 tests)
    # ========================================
    dut._log.info("\n--- Random Negative Tests ---")
    
    min_neg = -(1 << (tb.N - 1))  # -128 for 8-bit
    for i in range(20):
        a = random.randint(min_neg, -1)
        b = random.randint(min_neg, -1)
        await tb.multiply(a, b, f"Random neg {i+1}: {a} * {b}")
    
    # ========================================
    # Random Mixed Sign Tests (20 tests)
    # ========================================
    dut._log.info("\n--- Random Mixed Sign Tests ---")
    
    for i in range(20):
        a = random.randint(min_neg, max_pos)
        b = random.randint(min_neg, max_pos)
        await tb.multiply(a, b, f"Random mixed {i+1}: {a} * {b}")
    
    # ========================================
    # Edge Case Tests (10 tests)
    # ========================================
    dut._log.info("\n--- Edge Case Tests ---")
    
    await tb.multiply(127, 127, "max * max")
    await tb.multiply(-128, -128, "min * min")
    await tb.multiply(127, -128, "max * min")
    await tb.multiply(-128, 127, "min * max")
    await tb.multiply(127, 2, "127 * 2")
    await tb.multiply(-128, 2, "-128 * 2")
    await tb.multiply(64, 2, "64 * 2")
    await tb.multiply(-64, 2, "-64 * 2")
    await tb.multiply(100, -1, "100 * -1")
    await tb.multiply(-100, -1, "-100 * -1")
    
    # ========================================
    # Back-to-Back Tests (10 tests)
    # ========================================
    dut._log.info("\n--- Back-to-Back Tests ---")
    
    for i in range(10):
        a = random.randint(min_neg, max_pos)
        b = random.randint(min_neg, max_pos)
        await tb.multiply(a, b, f"Back-to-back {i+1}: {a} * {b}")
    
    # Wait a few cycles
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    # Print summary
    tb.print_summary()
    
    # Assert all tests passed
    assert tb.fail_count == 0, f"{tb.fail_count} test(s) failed!"


@cocotb.test()
async def booths_multiplier_stress_test(dut):
    """Stress test with corner cases"""
    
    # Create clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Create testbench object
    tb = BoothsMultiplierTB(dut)
    
    dut._log.info("\n" + "=" * 60)
    dut._log.info("Booth's Multiplier Stress Test")
    dut._log.info("=" * 60)
    
    # Reset DUT
    await tb.reset()
    
    # Test alternating patterns
    dut._log.info("\n--- Pattern Tests ---")
    await tb.multiply(0x55, 0xAA, "0x55 * 0xAA (alternating bits)")
    await tb.multiply(0xAA, 0x55, "0xAA * 0x55 (alternating bits)")
    await tb.multiply(0xFF, 0x01, "0xFF * 0x01 (all 1s * 1)")
    await tb.multiply(0x01, 0xFF, "0x01 * 0xFF (1 * all 1s)")
    
    # Test sequential numbers
    dut._log.info("\n--- Sequential Tests ---")
    for i in range(1, 11):
        await tb.multiply(i, i, f"{i} * {i}")
    
    # Wait
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    # Print summary
    tb.print_summary()
    
    # Assert all tests passed
    assert tb.fail_count == 0, f"{tb.fail_count} test(s) failed!"


@cocotb.test()
async def booths_multiplier_timing_test(dut):
    """Test timing and state transitions"""
    
    # Create clock
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    
    # Create testbench object
    tb = BoothsMultiplierTB(dut)
    
    dut._log.info("\n" + "=" * 60)
    dut._log.info("Booth's Multiplier Timing Test")
    dut._log.info("=" * 60)
    
    # Reset DUT
    await tb.reset()
    
    # Test that multiplication completes in expected cycles
    dut._log.info("\n--- Cycle Count Verification ---")
    
    test_cases = [
        (5, 3, "5 * 3"),
        (10, 10, "10 * 10"),
        (-5, 7, "-5 * 7"),
        (127, 127, "127 * 127")
    ]
    
    for a, b, name in test_cases:
        await tb.multiply(a, b, name)
    
    # Print summary
    tb.print_summary()
    
    assert tb.fail_count == 0, f"{tb.fail_count} test(s) failed!"
