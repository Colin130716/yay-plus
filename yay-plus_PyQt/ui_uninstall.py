# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'uninstall.ui'
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
from PySide6.QtWidgets import (QApplication, QDialog, QLabel, QPushButton,
    QSizePolicy, QWidget)

class Ui_Uninstall(object):
    def setupUi(self, Uninstall):
        if not Uninstall.objectName():
            Uninstall.setObjectName(u"Uninstall")
        Uninstall.resize(800, 600)
        icon = QIcon()
        icon.addFile(u"../../\u56fe\u7247/yay+.png", QSize(), QIcon.Normal, QIcon.Off)
        Uninstall.setWindowIcon(icon)
        self.pushButton = QPushButton(Uninstall)
        self.pushButton.setObjectName(u"pushButton")
        self.pushButton.setGeometry(QRect(120, 162, 551, 81))
        self.pushButton_2 = QPushButton(Uninstall)
        self.pushButton_2.setObjectName(u"pushButton_2")
        self.pushButton_2.setGeometry(QRect(120, 332, 551, 81))
        self.label = QLabel(Uninstall)
        self.label.setObjectName(u"label")
        self.label.setGeometry(QRect(120, 40, 551, 81))

        self.retranslateUi(Uninstall)

        QMetaObject.connectSlotsByName(Uninstall)
    # setupUi

    def retranslateUi(self, Uninstall):
        Uninstall.setWindowTitle(QCoreApplication.translate("Uninstall", u"yay+ Uninstall MainWindow", None))
        self.pushButton.setText(QCoreApplication.translate("Uninstall", u"\u5378\u8f7d Pacman \u5b89\u88c5\u7684\u8f6f\u4ef6\uff08\u5305\u62ec\u4f7f\u7528 makepkg \u7684 -i \u53c2\u6570\u5b89\u88c5\u7684\uff09", None))
        self.pushButton_2.setText(QCoreApplication.translate("Uninstall", u"\u5378\u8f7d Flatpak \u5b89\u88c5\u7684\u8f6f\u4ef6", None))
        self.label.setText(QCoreApplication.translate("Uninstall", u"<html><head/><body><p align=\"center\"><span style=\" font-size:36pt; font-weight:700;\">\u5378\u8f7d</span></p></body></html>", None))
    # retranslateUi

