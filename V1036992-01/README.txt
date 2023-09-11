Dear MySQL users,

MySQL Enterprise Backup 8.0.34, a new version of the online MySQL backup
tool, has been released. Moving forward, the 8.0 series will contain security
and bug fixes only. For new features please refer to the MySQL Enterprise
Backup 8.1.0 Innovation release.

MySQL Enterprise Backup 8.0.34 is now available for download from the My
Oracle Support (MOS) website as our latest GA release. This release will be
available on eDelivery (OSDC) after the next upload cycle. MySQL Enterprise
Backup is a commercial extension to the MySQL family of products.

MySQL Enterprise Backup 8.0.34 only supports the MySQL Server 8.0.34.
For earlier versions of MySQL 8.0, use the MySQL Enterprise Backup
version with the same version number as the server. For MySQL server
5.7, please use MySQL Enterprise Backup 4.1.

A brief summary of the changes in MySQL Enterprise Backup (MEB)
since the previous version is given below.

Changes in MySQL Enterprise Backup 8.0.34 (2023-07-18, General Availability)

     * Functionality Added or Changed

     * Bugs Fixed

Functionality Added or Changed

     * Important Change: For platforms on which OpenSSL libraries are
       bundled, the linked OpenSSL library for MySQL Enterprise Backup
       has been updated from OpenSSL 1.1.1 to OpenSSL 3.0. The exact
       version is now 3.0.9.  More information on changes from 1.1.1 to
       3.0 can be found at
       https://www.openssl.org/docs/man3.0/man7/migration_guide.html.
       (Bug #35475140)

     * Binary packages that include curl rather than linking to the
       system curl library have been upgraded to use curl 8.1.1. 
       (Bug #35329529)

Bugs Fixed

     * Backing up using redo log archiving
       (https://dev.mysql.com/doc/mysql-enterprise-backup/8.0/en/meb-redo-log-archiving.html)
       failed with a permission error when the OS user running
       mysqlbackup was a privileged user (for example, root). 
       (Bug #34392456)

On Behalf of the MySQL Engineering Team,
Nawaz Nazeer Ahamed
