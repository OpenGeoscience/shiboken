/*
 * Copyright 2013 Kitware, Inc.
 *
 * This file is part of the Shiboken Python Binding Generator project.
 *
 * Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
 *
 * Contact: PySide team <contact@pyside.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 */

#ifndef LISTSOURCES_H
#define LISTSOURCES_H

#include <QString>

class QIODevice;

class OutputLister
{
public:
    OutputLister() {}
    ~OutputLister() {}

    void setOutputDirectory(const QString &path);
    bool parseFile(const QString &fileName);

private:
    bool parseFile(QIODevice* device);

    QString m_outputPath;
};


#endif // LISTSOURCES_H
