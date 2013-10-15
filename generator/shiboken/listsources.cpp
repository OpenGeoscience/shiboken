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

#include "listsources.h"
#include "typesystem_p.h"
#include "reporthandler.h"
#include <QDir>
#include <QtXml>

class ListingHandler : public GenericHandler
{
public:
    ListingHandler(const QString &outputPath);

    bool startElement(const QString& namespaceURI, const QString& localName,
                      const QString& qName, const QXmlAttributes& atts);
    bool endElement(const QString& namespaceURI, const QString& localName, const QString& qName);

private:
    void printFile(const QString &name);
    void printFiles(const QString &prefix, const QStringList &extensions);
    void printWrapperFiles(const QStringList &names);

    QString m_packageName;
    QString m_outputPath;
    QStringList m_namespaceContext;

    QTextStream m_out;

    QSet<QString> classTagNames;
    QSet<QString> scopeTagNames;
};

ListingHandler::ListingHandler(const QString &outputPath)
        : m_outputPath(QDir::fromNativeSeparators(outputPath)), m_out(stdout)
{
    classTagNames.insert("object-type");
    classTagNames.insert("value-type");
    classTagNames.insert("interface-type");

    scopeTagNames.unite(classTagNames);
    scopeTagNames.insert("namespace-type");
}

static QString typeName(const QXmlAttributes &atts)
{
    if (atts.index("template") >= 0 && atts.index("args") >= 0) {
        QString name = QString("%1<%2>").arg(atts.value("template"), atts.value("args"));
        return name.replace("::", "_");
    } else {
        return atts.value("name").replace("::", "_");
    }
}

void ListingHandler::printFile(const QString &name)
{
    m_out << m_outputPath << '/' << name.toLower() << '\n';
}

void ListingHandler::printFiles(const QString &prefix, const QStringList &extensions)
{
    foreach (const QString &ext, extensions)
        printFile(QString("%1.%2").arg(prefix, ext));
}

void ListingHandler::printWrapperFiles(const QStringList &names)
{
    printFiles(names.join("_") + "_wrapper", QStringList() << "cpp" << "h");
}

bool ListingHandler::startElement(const QString &, const QString &localName, const QString &, const QXmlAttributes &atts)
{
    bool generate = true;
    if (atts.index("generate"))
        generate = convertBoolean(atts.value("generate"), "generate", true);

    if (localName == "typesystem") {
        m_packageName = atts.value("package");
        m_outputPath += "/" + m_packageName;
        printFile(m_packageName + "_module_wrapper.cpp");
        printFile(m_packageName + "_python.h");
    } else if (localName == "namespace-type") {
        m_namespaceContext.append(atts.value("name"));
        if (generate)
            printWrapperFiles(m_namespaceContext);
    } else if (classTagNames.contains(localName)) {
        m_namespaceContext.append(typeName(atts));
        if (generate)
            printWrapperFiles(m_namespaceContext);
    }

    return true;
}

bool ListingHandler::endElement(const QString &, const QString &localName, const QString &)
{
    if (scopeTagNames.contains(localName))
        m_namespaceContext.removeLast();

    return true;
}

void OutputLister::setOutputDirectory(const QString &path)
{
    m_outputPath = path;
}

bool OutputLister::parseFile(const QString &filename)
{
    QFile file(filename);
    if (!file.exists()) {
        ReportHandler::warning("Typesystem " + filename + " not found");
        return false;
    }

    return parseFile(&file);
}

bool OutputLister::parseFile(QIODevice* device)
{
    QXmlInputSource source(device);
    QXmlSimpleReader reader;
    ListingHandler handler(m_outputPath);

    reader.setContentHandler(&handler);
    reader.setErrorHandler(&handler);

    return reader.parse(&source, false);
}
