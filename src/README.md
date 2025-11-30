This is for the project

Things to test for segway:
Basic Checks
- Sending auth code starts the segway
- Sending stop code stops the segway
- Auth flow, start segway, apply some steering inputs, then stop it

PID Balancing
- Positive lean makes theta of segway converge to zero
- Negative lean makes theta of segway converge to zero
- Lean Changing midway still makes theta of segway converges to zero
- Applying a steer pot value for a right and left turns gives proper left and right speed values
- Check getting off segway mid balancing
- Segway wheels oscillate between 0 and 360 degrees as we apply speed tot hem

Safety
- Check dead time for all motor outputs
- Check too fast response

