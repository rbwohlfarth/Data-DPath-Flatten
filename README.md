# Local-Upload-Script

CPPA specific extensions for `ETL::Pipeline`. `ETL::Pipeline` provides the base functionality that we use to convert data from partner sites into our database format. These modules add extra sugar that make our scripts easier to read.

Install this repository in your local Perl instance.

1. `git pull`
1. `perl Makefile.PL`
1. `gmake`
1. `gmake test`
    - If there is an error, please contact the application developers. **DO NOT install.** Upload scripts will break.
1. `gmake install`

## Migrating old scripts

See the documentation for details about migrating old scripts based on 
**Data::ETL::PARS** to **Local::Upload::Script**.

`perldoc Local::Upload::Script`
