/*
 * This file is part of the API Extractor project.
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
#ifndef DOCPARSER_H
#define DOCPARSER_H

#include <QtCore/QString>
#include <QtCore/QDir>

#include "abstractmetalang.h"

class QDomDocument;
class QDomNode;
class QXmlQuery;

class DocParser
{
public:
    DocParser();
    virtual ~DocParser();
    virtual void fillDocumentation(AbstractMetaClass* metaClass) = 0;

    /**
     *   Process and retrieves documentation concerning the entire
     *   module or library.
     *   \return object containing module/library documentation information
     */
    virtual Documentation retrieveModuleDocumentation() = 0;

    void setDocumentationDataDirectory(const QString& dir)
    {
        m_docDataDir = dir;
    }

    /**
     *   Informs the location of the XML data generated by the tool
     *   (e.g.: DoxyGen, qdoc) used to extract the library's documentation
     *   comment.
     *   \return the path for the directory containing the XML data created
     *   from the library's documentation beign parsed.
     */
    QString documentationDataDirectory() const
    {
        return m_docDataDir;
    }

    void setLibrarySourceDirectory(const QString& dir)
    {
        m_libSourceDir = dir;
    }
    /**
     *   Informs the location of the library being parsed. The library
     *   source code is parsed for the documentation comments.
     *   \return the path for the directory containing the source code of
     *   the library beign parsed.
     */
    QString librarySourceDirectory() const
    {
        return m_libSourceDir;
    }

    void setPackageName(const QString& packageName)
    {
        m_packageName = packageName;
    }
    /**
     *   Retrieves the name of the package (or module or library) being parsed.
     *   \return the name of the package (module/library) being parsed
     */
    QString packageName() const
    {
        return m_packageName;
    }

    /**
    *   Process and retrieves documentation concerning the entire
    *   module or library.
    *   \param name module name
    *   \return object containing module/library documentation information
    *   \todo Merge with retrieveModuleDocumentation() on next ABI change.
    */
    virtual Documentation retrieveModuleDocumentation(const QString& name) = 0;

protected:
    QString getDocumentation(QXmlQuery& xquery, const QString& query,
                             const DocModificationList& mods) const;

private:
    QString m_packageName;
    QString m_docDataDir;
    QString m_libSourceDir;

    QString execXQuery(QXmlQuery& xquery, const QString& query) const;
    QString applyDocModifications(const DocModificationList& mods, const QString& xml) const;
};

#endif // DOCPARSER_H

