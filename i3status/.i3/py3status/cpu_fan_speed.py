# -*- coding: utf-8 -*-

from __future__ import division

import re

class GetData:
    """
    Get system status
    """

    def __init__(self, parent):
        self.py3 = parent.py3

    def cpuFan(self, zone):

        sensors = None
        command = ['sensors']
        if zone:
            try:
                sensors = self.py3.command_output(command + [zone])
            except:
                pass
        if not sensors:
            sensors = self.py3.command_output(command)
        m = re.search('Processor Fan: (.*)', sensors)

        if m:
            fan_speed = m.groups()[0]
        else:
            fan_speed = '?'

        return fan_speed

class Py3status:
    # available configuration parameters
    cache_timeout = 10
    zone = None
    format = "[CPU FAN: {fan_speed}]"

    def cpu_fan_speed(self):

        self.data = GetData(self)
        self.values = {'fan_speed': 0}
        fan_speed = self.data.cpuFan(self.zone)
        self.values['fan_speed'] = fan_speed
        response = {
            'full_text': self.py3.safe_format(self.format, self.values),
            'cached_until': self.py3.time_in(self.cache_timeout)
        }
        return response


if __name__ == "__main__":
    from py3status.module_test import module_test

    module_test(Py3status)
