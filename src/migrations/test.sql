INSERT INTO investors(
    id, name, email, password_hash, total_bonds, percentage_share, status, date_of_joining, national_id_number, created_at, image
) VALUES
(1, 'Caleb', 'caleb@example.com', '123456', 100, 10.5, 'active', '2022-01-15', 'A123456789', '2022-01-15 09:30:00', 'alice.jpg'),
(2, 'Bob Smith', 'bob.smith@example.com', '5f4dcc3b5aa765d61d8327deb882cf99', 150, 15.0, 'active', '2021-11-20', 'B987654321', '2021-11-20 10:00:00', 'bob.png'),
(3, 'Carol Lee', 'carol.lee@example.com', '7c6a180b36896a0a8c02787eeafb0e4c', 200, 20.0, 'active', '2023-03-10', 'C192837465', '2023-03-10 08:45:00', 'carol.jpg'),
(4, 'David Kim', 'david.kim@example.com', '6cb75f652a9b52798eb6cf2201057c73', 120, 12.0, 'suspended', '2022-07-05', 'D564738291', '2022-07-05 11:15:00', 'david.png'),
(5, 'Eva Green', 'eva.green@example.com', '8d3533d75ae2c3966d7e0d4fcc69216b', 180, 18.5, 'active', '2021-09-25', 'E019283746', '2021-09-25 14:20:00', 'eva.jpg');