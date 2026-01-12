# TechHealthDB
TechHealthDb is a fully‑designed SQL Server database project that demonstrates my ability to build, optimize, and document real‑world relational database systems. The project simulates a health‑tracking platform where customers use wearable devices, purchase products, interact with coaches, and generate monthly health metrics.

This project includes a production‑style automation workflow for TechHealthDB, using SQL Server Agent to manage daily backups and weekly retention cleanup.

1. Daily Full Backup Job
Purpose:  
Creates a timestamped full backup of the TechHealthDB database every day at 02:00 AM.

-Generates a unique .bak file for each day
-Uses ISO‑style timestamps for clean versioning
-Ensures backups never overwrite each other
-Runs automatically via SQL Server Agent

3. Weekly Cleanup Job
Purpose:  
Deletes backup files older than 7 days to maintain storage hygiene.

Technology:  
SQL Server Agent → CmdExec Step
