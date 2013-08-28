#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright 2013 Kitware, Inc.
#
# This file is part of the Shiboken Python Bindings Generator project.
#
# Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
#
# Contact: PySide team <contact@pyside.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation. Please
# review the following information to ensure the GNU Lesser General
# Public License version 2.1 requirements will be met:
# http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
# #
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA

'''Test cases for a template pointer class.'''

import sys
import unittest

from sample import SimpleObject

class TestPointer(unittest.TestCase):
    '''Test cases for a template pointer class.'''

    def testRedirection(self):
        '''Test method redirection on template pointer class.'''
        o1 = SimpleObject.create()
        o2 = SimpleObject.create()
        self.assertGreater(o2.id(), o1.id())

    def testAddedMethod(self):
        '''Test method redirection on template pointer class.'''
        o = SimpleObject.create()
        self.assertEqual(type(o.get()), SimpleObject)

    def testReferenceCounting(self):
        '''Test basic wrapping of template pointer class.'''
        o1 = SimpleObject.create()
        o2 = SimpleObject.create()
        self.assertEqual(SimpleObject.count(), 2)
        del o1
        self.assertEqual(SimpleObject.count(), 1)
        del o2
        self.assertEqual(SimpleObject.count(), 0)

    def testTypeAlias(self):
        '''Test that typedef of type template instantiation is recognized.'''
        o1 = SimpleObject.create()
        o2 = SimpleObject.createAliased()
        self.assertEqual(type(o1), type(o2))

if __name__ == '__main__':
    unittest.main()

