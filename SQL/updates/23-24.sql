# Updating DB from 23-24, -dearmochi
# Adds new type on connection failure

# Add new column to connection_log
ALTER TABLE `connection_log` MODIFY COLUMN `result` ENUM('ESTABLISHED','DROPPED - IPINTEL', 'DROPPED - BANNED', 'DROPPED - INVALID', 'DROPPED - ELSEWHERE');
