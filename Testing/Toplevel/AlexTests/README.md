# Segway Verification Progress

## Testbenches

- **Safety_tb**: In progress
- **Segway_auth_flow_tb**: Completed Needs Testing
- **Segway_balance_tb**: Completed and tested
- **Segway_steer_tb**: In Progress

  ## Safety_tb

  ## Segway_auth_flow_tb

    1. (No step-off during steering): Sends an auth/start command, verifies that the Segway motors start moving, then stops it and checks that all motor speeds return to zero.

    2.  (Includes step-off): Starts the Segway, applies a steering input, and confirms that the motors respond correctly; then stops the Segway and checks that all motor speeds return to zero.

    3. (Includes step-off and control reset): Starts the Segway, applies a steering input, stops it, and ensures that motor speeds are zero and steering control signals are properly reset.

  ## Segway_balance_tb
    1. Segway_balance_tb: Checks whether differences in left/right weights cause the Segway platform angle (theta_platform) to change appropriately.
    
  ## Segway_steer_tb