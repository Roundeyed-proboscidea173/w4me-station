(module
  (type $sixteen-results
    (func
      (result
        i32 i32 i32 i32 i32 i32 i32 i32
        i32 i32 i32 i32 i32 i32 i32 i32)))

  (memory (export "memory") 1)

  (func $block-result (result i32)
    (block $done (result i32)
      i32.const 11
      br $done
      unreachable))

  (func $loop-parameter (result i32)
    (local $value i32)
    i32.const 3
    (loop $again (param i32) (result i32)
      local.set $value
      local.get $value
      i32.const 1
      i32.sub
      local.tee $value
      local.get $value
      br_if $again))

  (func $if-result (result i32)
    i32.const 1
    (if $done (result i32)
      (then
        i32.const 22
        br $done
        unreachable)
      (else
        i32.const 23)))

  (func $function-branch (result i32)
    i32.const 33
    br 0
    unreachable)

  (func $nested-depth (result i32)
    (block $outer (result i32)
      (block $inner (result i32)
        i32.const 44
        br $outer
        unreachable)))

  (func $unreachable-polymorphic (result i64)
    (block $done (result i64)
      i64.const 55
      br $done
      drop
      br $done))

  (func $table-block-repeated (result i32)
    (block $outer (result i32)
      (block $inner (result i32)
        i32.const 66
        i32.const 0
        br_table $outer $outer $inner $outer)
      drop
      i32.const 67))

  (func $table-block-inner (result i32)
    (block $outer (result i32)
      (block $inner (result i32)
        i32.const 76
        i32.const 2
        br_table $outer $outer $inner $outer)
      drop
      i32.const 77))

  (func $table-block-default (result i32)
    (block $outer (result i32)
      (block $inner (result i32)
        i32.const 86
        i32.const 9
        br_table $outer $outer $inner $outer)
      drop
      i32.const 87))

  (func $table-loop (result i32)
    (local $value i32)
    (block $done (result i32)
      i32.const 2
      (loop $again (param i32) (result i32)
        local.set $value
        local.get $value
        i32.const 1
        i32.sub
        local.tee $value
        local.get $value
        i32.eqz
        br_table $again $done $done)))

  (func $table-function (result i32)
    i32.const 99
    i32.const 0
    br_table 0 0)

  (func $max-arity (type $sixteen-results)
    (block $done (type $sixteen-results)
      i32.const 0
      i32.const 1
      i32.const 2
      i32.const 3
      i32.const 4
      i32.const 5
      i32.const 6
      i32.const 7
      i32.const 8
      i32.const 9
      i32.const 10
      i32.const 11
      i32.const 12
      i32.const 13
      i32.const 14
      i32.const 15
      i32.const 0
      br_table $done $done))

  (func (export "case_block_result")
    i32.const 0
    call $block-result
    i32.store)

  (func (export "case_loop_parameter")
    i32.const 4
    call $loop-parameter
    i32.store)

  (func (export "case_if_result")
    i32.const 8
    call $if-result
    i32.store)

  (func (export "case_function_branch")
    i32.const 12
    call $function-branch
    i32.store)

  (func (export "case_nested_depth")
    i32.const 16
    call $nested-depth
    i32.store)

  (func (export "case_unreachable_polymorphic")
    i32.const 20
    call $unreachable-polymorphic
    i64.store)

  (func (export "case_table_block_repeated")
    i32.const 28
    call $table-block-repeated
    i32.store)

  (func (export "case_table_block_inner")
    i32.const 32
    call $table-block-inner
    i32.store)

  (func (export "case_table_block_default")
    i32.const 36
    call $table-block-default
    i32.store)

  (func (export "case_table_loop")
    i32.const 40
    call $table-loop
    i32.store)

  (func (export "case_table_function")
    i32.const 44
    call $table-function
    i32.store)

  (func (export "case_max_arity")
    call $max-arity
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop)

  (func (export "update")
    i32.const 0
    call $block-result
    i32.store
    i32.const 4
    call $loop-parameter
    i32.store
    i32.const 8
    call $if-result
    i32.store
    i32.const 12
    call $function-branch
    i32.store
    i32.const 16
    call $nested-depth
    i32.store
    i32.const 20
    call $unreachable-polymorphic
    i64.store
    i32.const 28
    call $table-block-repeated
    i32.store
    i32.const 32
    call $table-block-inner
    i32.store
    i32.const 36
    call $table-block-default
    i32.store
    i32.const 40
    call $table-loop
    i32.store
    i32.const 44
    call $table-function
    i32.store
    call $max-arity
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop
    drop))
