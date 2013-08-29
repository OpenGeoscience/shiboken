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

#ifndef POINTER_H
#define POINTER_H

#include <list>

#include "libsamplemacros.h"

template <typename T>
class Pointer
{
public:
    Pointer() : m_obj(0), m_ref(0) {}

    explicit Pointer(T *obj) : m_obj(obj),  m_ref(new int)
    {
        *m_ref = 1;
    }

    Pointer(const Pointer<T> &other) : m_obj(other.m_obj), m_ref(other.m_ref)
    {
        ++(*m_ref);
    }

    Pointer& operator=(const Pointer<T> &other)
    {
        release();
        m_obj = other.m_obj;
        m_ref = other.m_ref;
        ++(*m_ref);
        return *this;
    }

    virtual ~Pointer()
    {
        release();
    }

    inline T* get() const { return m_obj; }

private:
    void release()
    {
        if (m_ref && --(*m_ref) <= 0) {
            delete m_obj;
            delete m_ref;
        }
    }

    T *m_obj;
    int *m_ref;
};

class SimpleObject;
typedef Pointer<SimpleObject> SimpleObjectPointer;

class LIBSAMPLE_API SimpleObject
{
public:
    ~SimpleObject();

    inline int id() const { return m_id; }

    static Pointer<SimpleObject> create();
    static SimpleObjectPointer createAliased() { return create(); }
    static int count();

private:
    SimpleObject(int);

    int m_id;
};

namespace PointerNamespace
{

template <typename T> class Pointer
{
public:
    Pointer() {}
    Pointer(T* obj) : m_ptr(obj) {}
    inline T* get() const { return m_ptr.get(); }

private:
    ::Pointer<T> m_ptr;
};

class LIBSAMPLE_API NamespaceObject
{
public:
    ::std::list<int> numbers(int first, int count) const;
};

typedef Pointer<NamespaceObject> NamespaceObjectPointer;

NamespaceObjectPointer createNamespaceObject();

}

#endif // POINTER_H

