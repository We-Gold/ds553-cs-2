import os
import sys
from threading import Thread
from time import sleep

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import app

TIMEOUT = 10 # seconds

def test_app_starts():
    # Start a thread for testing app in a separate thread
    # Based on this: https://www.reddit.com/r/learnpython/comments/16iv4kd/how_to_make_a_program_terminate_after_a_certain/
    t = Thread(target=app.demo.launch, daemon=True)
    t.start()

    exit_timer = TIMEOUT
    sleep(exit_timer)