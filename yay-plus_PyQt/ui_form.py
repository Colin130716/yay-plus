# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'form.ui'
##
## Created by: Qt User Interface Compiler version 6.7.0
##
## WARNING! All changes made in this file will be lost when recompiling UI file!
################################################################################

from PySide6.QtCore import (QCoreApplication, QDate, QDateTime, QLocale,
    QMetaObject, QObject, QPoint, QRect,
    QSize, QTime, QUrl, Qt)
from PySide6.QtGui import (QBrush, QColor, QConicalGradient, QCursor,
    QFont, QFontDatabase, QGradient, QIcon,
    QImage, QKeySequence, QLinearGradient, QPainter,
    QPalette, QPixmap, QRadialGradient, QTransform)
from PySide6.QtWidgets import (QApplication, QLabel, QMainWindow, QPushButton,
    QSizePolicy, QWidget)

class Ui_Home(object):
    def setupUi(self, Home):
        if not Home.objectName():
            Home.setObjectName(u"Home")
        Home.resize(800, 600)
        icon = QIcon()
        icon.addFile(u"../../\u56fe\u7247/yay+.png", QSize(), QIcon.Normal, QIcon.Off)
        Home.setWindowIcon(icon)
        self.centralwidget = QWidget(Home)
        self.centralwidget.setObjectName(u"centralwidget")
        self.title = QLabel(self.centralwidget)
        self.title.setObjectName(u"title")
        self.title.setGeometry(QRect(0, 30, 801, 81))
        self.pushButton_install = QPushButton(self.centralwidget)
        self.pushButton_install.setObjectName(u"pushButton_install")
        self.pushButton_install.setGeometry(QRect(50, 170, 170, 70))
        self.pushButton_uninstall = QPushButton(self.centralwidget)
        self.pushButton_uninstall.setObjectName(u"pushButton_uninstall")
        self.pushButton_uninstall.setGeometry(QRect(310, 170, 171, 71))
        self.pushButton_run_flatpak = QPushButton(self.centralwidget)
        self.pushButton_run_flatpak.setObjectName(u"pushButton_run_flatpak")
        self.pushButton_run_flatpak.setGeometry(QRect(570, 170, 171, 71))
        self.pushButton_exit = QPushButton(self.centralwidget)
        self.pushButton_exit.setObjectName(u"pushButton_exit")
        self.pushButton_exit.setGeometry(QRect(310, 340, 171, 71))
        Home.setCentralWidget(self.centralwidget)

        self.retranslateUi(Home)
        self.pushButton_exit.pressed.connect(Home.close)

        QMetaObject.connectSlotsByName(Home)
    # setupUi

    def retranslateUi(self, Home):
        Home.setWindowTitle(QCoreApplication.translate("Home", u"yay+ PyQt Version(Beta)", None))
        self.title.setText(QCoreApplication.translate("Home", u"<html><head/><body><p align=\"center\"><span style=\" font-size:20pt; font-weight:700;\">yay+ PyQt\u7248\uff08\u6d4b\u8bd5\u4e2d\uff09</span></p><p align=\"center\"><span style=\" font-size:12pt; font-weight:700;\">\u7248\u672c0.1 Beta</span></p></body></html>", None))
        self.pushButton_install.setText(QCoreApplication.translate("Home", u"\u5b89\u88c5", None))
        self.pushButton_uninstall.setText(QCoreApplication.translate("Home", u"\u5378\u8f7d", None))
        self.pushButton_run_flatpak.setText(QCoreApplication.translate("Home", u"\u8fd0\u884c\uff08Flatpak\u8f6f\u4ef6\u5305\uff09", None))
        self.pushButton_exit.setText(QCoreApplication.translate("Home", u"\u9000\u51fa", None))
    # retranslateUi

