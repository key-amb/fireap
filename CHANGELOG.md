## 0.2.0 (2016/3/20)

Feature:

- Introduce `service`, `service_regexp` param accompanied with `tag` and
`tag_regexp` in configuration to filter task propagation targets.

## 0.1.3 (2016/3/19)

Bug Fix:

- Add `::` before `Logger::` constant -
https://github.com/key-amb/fireap/commit/d97c6f62019960701d07c61be379ded2908ecf6b
  - In v0.1.2, when command fails in `reap` mode, program exits irregularly.

Improve:

- Show caller info and full command-line on every log line.
- Add `[Dry-run]` string as header with each log line when `--dry-run` option is
given for `fireap reap`.

And documentation wiki is available now.

## 0.1.2 (2016/3/18) obsolete

Change:

- General:
  - Write log to logfile in addtion to STDIN when logfile is configured.
- In `monitor` command:
  - Suppress logging on continuous monitoring mode.

## 0.1.1 (2016/3/18)

Fix:

- Not to fail when out-of-date node data is found in Kv.

## 0.1.0 (2016/3/18)

First release.
