# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'uninstall_pacman.ui'
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
from PySide6.QtWidgets import (QApplication, QDialog, QLabel, QLineEdit,
    QPushButton, QSizePolicy, QWidget)

class Ui_Uninstall_Pacman(object):
    def setupUi(self, Uninstall_Pacman):
        if not Uninstall_Pacman.objectName():
            Uninstall_Pacman.setObjectName(u"Uninstall_Pacman")
        Uninstall_Pacman.resize(800, 600)
        icon = QIcon()
        icon.addFile(u"icons/256x256.png", QSize(), QIcon.Normal, QIcon.Off)
        Uninstall_Pacman.setWindowIcon(icon)
        self.label = QLabel(Uninstall_Pacman)
        self.label.setObjectName(u"label")
        self.label.setGeometry(QRect(98, 40, 601, 91))
        self.lineEdit = QLineEdit(Uninstall_Pacman)
        self.lineEdit.setObjectName(u"lineEdit")
        self.lineEdit.setGeometry(QRect(92, 180, 611, 27))
        self.pushButton_no = QPushButton(Uninstall_Pacman)
        self.pushButton_no.setObjectName(u"pushButton_no")
        self.pushButton_no.setGeometry(QRect(440, 510, 111, 41))
        self.pushButton_yes = QPushButton(Uninstall_Pacman)
        self.pushButton_yes.setObjectName(u"pushButton_yes")
        self.pushButton_yes.setGeometry(QRect(590, 510, 111, 41))

        self.retranslateUi(Uninstall_Pacman)

        QMetaObject.connectSlotsByName(Uninstall_Pacman)
    # setupUi

    def retranslateUi(self, Uninstall_Pacman):
        Uninstall_Pacman.setWindowTitle(QCoreApplication.translate("Uninstall_Pacman", u"Dialog", None))
        self.label.setText(QCoreApplication.translate("Uninstall_Pacman", u"<html><head/><body><p align=\"center\"><span style=\" font-size:36pt; font-weight:700;\">\u5378\u8f7d</span></p></body></html>", None))
        self.lineEdit.setText(QCoreApplication.translate("Uninstall_Pacman", u"\u4fee\u6539\u6b64\u5904\u6587\u5b57\u4fee\u6539\u4e3a\u4f60\u8981\u5378\u8f7d\u7684\u8f6f\u4ef6\u540d\u79f0\uff08\u652f\u6301\u591a\u4e2a\uff0c\u7528\u7a7a\u683c\u9694\u5f00\uff09", None))
        self.pushButton_no.setText(QCoreApplication.translate("Uninstall_Pacman", u"\u53d6\u6d88", None))
        self.pushButton_yes.setText(QCoreApplication.translate("Uninstall_Pacman", u"\u786e\u5b9a", None))
    # retranslateUi

