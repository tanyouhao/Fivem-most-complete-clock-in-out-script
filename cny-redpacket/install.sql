-- ============================================================
-- CNY RED PACKET - DATABASE SETUP
-- Run this SQL in your FiveM database (es_extended)
-- ============================================================

-- Normal Red Packet item
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`)
VALUES ('cny_redpacket', 'Red Packet', 1, 0, 1)
ON DUPLICATE KEY UPDATE `label` = 'Red Packet';

-- Golden Red Packet item
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`)
VALUES ('cny_redpacket_gold', 'Golden Red Packet', 1, 1, 1)
ON DUPLICATE KEY UPDATE `label` = 'Golden Red Packet';
