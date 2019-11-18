# Changelog
All notable changes to this project will be documented in this file.

## [0.4.0] 2019-11-18
### Added
- `Sequel.extension(:deferrable_foreign_keys)` - makes foreign keys constraints deferrable by default;

## [0.3.2] 2018-07-03
### Added
- Support sequel expessions in `with_rates`

## [0.3.0] 2018-04-24
### Added
- `currency_column` param for `CurrencyRates.with_rates`;

## [0.2.0] 2018-03-28
### Added
- `Sequel.extension(:methods_in_migrations)` - support for method definitions in `Sequel.migration` instructions;
