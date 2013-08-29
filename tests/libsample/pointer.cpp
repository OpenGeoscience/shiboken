/*
 * Copyright 2013 Kitware, Inc.
 *
 * This file is part of the Shiboken Python Binding Generator project.
 *
 * Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
 *
 * Contact: PySide team <contact@pyside.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "pointer.h"

static int nextId = 0;
static int counter = 0;

SimpleObject::SimpleObject(int id) : m_id(id)
{
    ++counter;
}

SimpleObject::~SimpleObject()
{
    --counter;
}

Pointer<SimpleObject> SimpleObject::create()
{
    return Pointer<SimpleObject>(new SimpleObject(++nextId));
}

int SimpleObject::count()
{
    return counter;
}

std::list<int> PointerNamespace::NamespaceObject::numbers(int first, int count) const
{
    std::list<int> result;
    while (count--)
        result.push_back(first++);
    return result;
}

PointerNamespace::NamespaceObjectPointer PointerNamespace::createNamespaceObject()
{
    return NamespaceObjectPointer(new NamespaceObject);
}
