SELECT no_plan();
-- SELECT plan(2);

-- BEGIN;

CREATE TABLE test(i INT);

INSERT INTO test SELECT * FROM generate_series(1,2);

SELECT diag('Items: ' || i) FROM test;

SELECT cmp_ok(i, '>', 0, 'All rows are natural numbers') FROM test;

SELECT is(COUNT(*), 2::bigint) FROM test;

SELECT finish();

-- ROLLBACK;
