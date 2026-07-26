(module
  (type $actual (func (result i32)))
  (type $expected (func (result i32)))
  (type $near_miss (func (result i64)))
  (type $update (func))

  (import "env" "memory" (memory 0 65536))
  (table 1 funcref)
  (elem (i32.const 0) $target)

  (func $target (type $actual) (result i32)
    i32.const 123456789)

  (func (export "update") (type $update)
    i32.const 20040
    i32.const 0
    call_indirect (type $expected)
    i32.store)

  (func (export "mismatch") (type $update)
    i32.const 0
    call_indirect (type $near_miss)
    drop))
