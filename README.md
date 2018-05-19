# Optimize-SqlIaasVm
Powershell interactive script used to optimize a SQL Server Azure IaaS VM.

This script represents my first attempt to create an automated solution for applying best practices on a SQL Server VM in Azure IaaS, as per <a href="https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sql/virtual-machines-windows-sql-performance">official documentation</a>.

My coding skills are very low, and it needs a refactoring in order to make it readable; in the next future, I'll probably integrate DBATools module (https://dbatools.io) to replace some basic function I use with stronger implementations of them; in many places I've just reinvented the wheel, and it didn't even come out too round :)

I used parts of this script to implement an Azure Custom Script Extension used in my <a href="https://github.com/OmegaMadLab/OptimizedSqlVm">Optimized SQL Server ARM Template</a>.

