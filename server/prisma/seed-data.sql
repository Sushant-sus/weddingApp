-- Optional sample data. Safe to run multiple times only if tables are empty;
-- otherwise it just appends more rows. Run AFTER seed-procedures.sql.
DO $$
DECLARE g1 UUID; g2 UUID; g3 UUID;
BEGIN
  IF (SELECT COUNT(*) FROM wedding.guests WHERE deleted_at IS NULL) > 0 THEN
    RAISE NOTICE 'Guests already exist — skipping sample data.';
    RETURN;
  END IF;

  g1 := (wedding.sp_guest_create('Sharma Family','CHULEY','GROOM',6,'9800000001','Kathmandu','Close relatives')->>'id')::UUID;
  g2 := (wedding.sp_guest_create('Maharjan Family','CHULEY','BRIDE',4,'9800000002','Lalitpur',NULL)->>'id')::UUID;
  g3 := (wedding.sp_guest_create('Ramesh Thapa','SINGLE','BOTH',1,'9800000003','Bhaktapur','College friend')->>'id')::UUID;

  PERFORM wedding.sp_guest_update(g1, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, 'CONFIRMED');
  PERFORM wedding.sp_guest_update(g2, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, 'CONFIRMED');

  PERFORM wedding.sp_gift_create(g1,'CASH',25000,NULL,NOW(),'Envelope');
  PERFORM wedding.sp_gift_create(g2,'KIND',NULL,'Dinner set',NOW(),NULL);
  PERFORM wedding.sp_gift_create(g3,'CASH',5100,NULL,NOW(),NULL);

  PERFORM wedding.sp_itinerary_create('Haldi Ceremony', CURRENT_DATE, '09:00 AM', 'Turmeric ceremony', '11:00 AM', 'Home Garden', 'Aunt Sita', 'RITUAL', 0);
  PERFORM wedding.sp_itinerary_create('Wedding Ceremony', CURRENT_DATE, '11:30 AM', 'Main rituals', '02:00 PM', 'Grand Hall', 'Pandit Ji', 'CEREMONY', 1);
  PERFORM wedding.sp_itinerary_create('Lunch', CURRENT_DATE, '02:00 PM', NULL, '03:30 PM', 'Banquet', 'Catering Lead', 'MEAL', 2);
  PERFORM wedding.sp_itinerary_create('Reception', CURRENT_DATE, '06:00 PM', 'Evening party', '10:00 PM', 'Grand Hall', 'Event Manager', 'RECEPTION', 3);

  PERFORM wedding.sp_cost_create('Venue','Grand Hall booking',300000,250000,'Hyatt','PARTIAL','Advance paid');
  PERFORM wedding.sp_cost_create('Catering','Lunch & dinner (500 pax)',400000,NULL,'Annapurna Caterers','UNPAID',NULL);
  PERFORM wedding.sp_cost_create('Decoration','Stage & flowers',150000,160000,'Bloom Decor','PAID',NULL);
  PERFORM wedding.sp_cost_create('Photography','Photo + video',120000,120000,'LensCraft','PAID',NULL);
END $$;
