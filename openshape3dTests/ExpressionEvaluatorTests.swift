//
//  ExpressionEvaluatorTests.swift
//  openshape3dTests
//
//  Dimension-field arithmetic evaluator (plan §C2, spec §18).
//

import XCTest
@testable import openshape3d

final class ExpressionEvaluatorTests: XCTestCase {

    func testDimensionDiagnosticsUseParsedDenominators() {
        XCTAssertEqual(ExpressionEvaluator.validationMessage(" ", variables: [:]),
                       "A value is needed but none is given.")
        for expression in ["1/0", "1/(2-2)", "1/zero", "1/0 mm"] {
            XCTAssertEqual(ExpressionEvaluator.validationMessage(expression, variables: ["zero": 0]),
                           "Expression is invalid. Cannot divide by zero.", expression)
        }
        XCTAssertEqual(ExpressionEvaluator.validationMessage("2+", variables: [:]),
                       "Expression contains a syntax error that cannot be parsed.")
        XCTAssertNil(ExpressionEvaluator.validationMessage("1/0.5", variables: [:]))
        XCTAssertNil(ExpressionEvaluator.validationMessage("1/zero", variables: ["zero": 2]))
    }

    func testPlainNumbers() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("20"), 20)
        XCTAssertEqual(ExpressionEvaluator.evaluate("25.4"), 25.4)
        XCTAssertEqual(ExpressionEvaluator.evaluate("  7  "), 7)
    }

    func testArithmetic() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("25.4/2"), 12.7)
        XCTAssertEqual(ExpressionEvaluator.evaluate("10 + 5"), 15)
        XCTAssertEqual(ExpressionEvaluator.evaluate("3*4"), 12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("100 - 30 - 20"), 50)
        XCTAssertEqual(ExpressionEvaluator.evaluate("(1+2)*3"), 9)
        XCTAssertEqual(ExpressionEvaluator.evaluate("2 + 3 * 4"), 14) // precedence
    }

    func testUnaryAndUnits() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("-5 + 8"), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("20 mm"), 20)
        XCTAssertEqual(ExpressionEvaluator.evaluate("=42"), 42)
    }

    func testMalformedReturnsNil() {
        XCTAssertNil(ExpressionEvaluator.evaluate(""))
        XCTAssertNil(ExpressionEvaluator.evaluate("abc"))
        XCTAssertNil(ExpressionEvaluator.evaluate("5 +"))
        XCTAssertNil(ExpressionEvaluator.evaluate("(1+2"))
        XCTAssertNil(ExpressionEvaluator.evaluate("1/0"))
        XCTAssertNil(ExpressionEvaluator.evaluate("* 3"))
    }

    // MARK: - Phase D: variables

    func testVariableReference() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("w * 2", variables: ["w": 5]), 10)
        XCTAssertEqual(ExpressionEvaluator.evaluate("w", variables: ["w": 5]), 5)
        XCTAssertEqual(ExpressionEvaluator.evaluate("b + a", variables: ["a": 2, "b": 6]), 8)
        XCTAssertEqual(ExpressionEvaluator.evaluate("cap_height / 2", variables: ["cap_height": 10]), 5)
    }

    func testUnknownIdentifierReturnsNil() {
        XCTAssertNil(ExpressionEvaluator.evaluate("w * 2", variables: [:]))
        XCTAssertNil(ExpressionEvaluator.evaluate("a + b", variables: ["a": 1]))
    }

    func testTrailingUnitStillWorksWithVariables() {
        // "20 mm" must still strip the unit even in the variable-aware path.
        XCTAssertEqual(ExpressionEvaluator.evaluate("20 mm", variables: ["w": 5]), 20)
        // A trailing variable ref must NOT be stripped as a unit.
        XCTAssertEqual(ExpressionEvaluator.evaluate("2 + w", variables: ["w": 3]), 5)
    }

    func testFunctionLibrary() {
        let v: [String: Double] = [:]
        XCTAssertEqual(ExpressionEvaluator.evaluate("sqrt(9)", variables: v), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("mod(7, 3)", variables: v), 1)
        XCTAssertEqual(ExpressionEvaluator.evaluate("min(3, 1, 2)", variables: v), 1)
        XCTAssertEqual(ExpressionEvaluator.evaluate("max(3, 1, 2)", variables: v), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("avg(2, 4)", variables: v), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("floor(2.7)", variables: v), 2)
        XCTAssertEqual(ExpressionEvaluator.evaluate("ceil(2.1)", variables: v), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("round(2.5)", variables: v), 3)
        XCTAssertEqual(ExpressionEvaluator.evaluate("abs(-4)", variables: v), 4)
        XCTAssertEqual(ExpressionEvaluator.evaluate("sign(-7)", variables: v), -1)
        XCTAssertEqual(ExpressionEvaluator.evaluate("sign(7)", variables: v), 1)
        XCTAssertEqual(ExpressionEvaluator.evaluate("sign(0)", variables: v), 0)
        XCTAssertEqual(ExpressionEvaluator.evaluate("pi()", variables: v)!, Double.pi, accuracy: 1e-12)
    }

    func testTrigFunctionsInRadians() {
        let v: [String: Double] = [:]
        XCTAssertEqual(ExpressionEvaluator.evaluate("radians(180)", variables: v)!, Double.pi, accuracy: 1e-12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("sin(0)", variables: v)!, 0, accuracy: 1e-12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("cos(0)", variables: v)!, 1, accuracy: 1e-12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("sin(radians(90))", variables: v)!, 1, accuracy: 1e-12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("atan2(1, 1)", variables: v)!, Double.pi / 4, accuracy: 1e-12)
        XCTAssertEqual(ExpressionEvaluator.evaluate("atan(1)", variables: v)!, Double.pi / 4, accuracy: 1e-12)
    }

    func testFunctionArgErrors() {
        XCTAssertNil(ExpressionEvaluator.evaluate("sqrt(1, 2)", variables: [:]))     // too many args
        XCTAssertNil(ExpressionEvaluator.evaluate("mod(5)", variables: [:]))         // too few args
        XCTAssertNil(ExpressionEvaluator.evaluate("mod(5, 0)", variables: [:]))      // div by zero
        XCTAssertNil(ExpressionEvaluator.evaluate("pi(3)", variables: [:]))          // pi takes none
        XCTAssertNil(ExpressionEvaluator.evaluate("nope(3)", variables: [:]))        // unknown function
        XCTAssertNil(ExpressionEvaluator.evaluate("min()", variables: [:]))          // needs >=1 arg
    }

    func testVariablesUsedInsideFunctions() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("sqrt(w)", variables: ["w": 16]), 4)
        XCTAssertEqual(ExpressionEvaluator.evaluate("max(a, b, 5)", variables: ["a": 2, "b": 9]), 9)
    }

    func testExistingArithmeticStillWorksThroughVariablePath() {
        XCTAssertEqual(ExpressionEvaluator.evaluate("(1+2)*3", variables: [:]), 9)
        XCTAssertEqual(ExpressionEvaluator.evaluate("2 + 3 * 4", variables: [:]), 14)
        XCTAssertEqual(ExpressionEvaluator.evaluate("-5 + 8", variables: [:]), 3)
        XCTAssertNil(ExpressionEvaluator.evaluate("1/0", variables: [:]))
    }

    func testIdentifiersInText() {
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "w * 2"), ["w"])
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "b + a"), ["a", "b"])
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "cap_height / 2 + w2"), ["cap_height", "w2"])
        // Function names are excluded; only their variable arguments remain.
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "sqrt(w) + max(a, 5)"), ["w", "a"])
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "pi() * r"), ["r"])
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "3 + 4"), [])
        // Not substring matching: "wing" is one token, not "w" + "ing".
        XCTAssertEqual(ExpressionEvaluator.identifiers(in: "wing * 2"), ["wing"])
    }
}
