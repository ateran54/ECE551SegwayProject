This is for the project

Things to test for segway:
Basic Checks
- Sending auth code starts the segway [x]
- Sending stop code stops the segway
- Auth flow, start segway, apply some steering inputs, then stop it

PID Balancing/Physics
- Positive lean makes theta of segway converge to zero[x]
- Negative lean makes theta of segway converge to zero[x]
- Lean Changing midway still makes theta of segway converges to zero[x]
- Applying a steer pot value for a right and left turns gives proper left and right speed values as well as making segway angle converge to around 0[x]
- Check getting off segway mid balancing
- Ramp up steer pot gives proper spped values at different points, also check for converge

Safety
- Check dead time for all motor outputs
- Check too fast is asserted when the motor speed is too high
- Check that when pwr_up is low, motor speeds go to zero[o]
- Check that over current being set to high stops the segway[o]
- Check that soft start timer in PID control works properly and actually ramps up[o]
- Check that when a shutdown command is sent, that the segway doesnt power off and that the motors are still running




MISC
- Check piezo during too fast and when the segway is on and off, can check internal signals of the piezo


