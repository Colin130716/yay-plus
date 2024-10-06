# -*- coding: utf-8 -*-

from PySide6.QtCore import (QCoreApplication, QDate, QDateTime, QLocale,
    QMetaObject, QObject, QPoint, QRect,
    QSize, QTime, QUrl, Qt)
from PySide6.QtGui import (QBrush, QColor, QConicalGradient, QCursor,
    QFont, QFontDatabase, QGradient, QIcon,
    QImage, QKeySequence, QLinearGradient, QPainter,
    QPalette, QPixmap, QRadialGradient, QTransform)
from PySide6.QtWidgets import (QApplication, QLineEdit, QMainWindow, QPushButton,
    QSizePolicy, QStatusBar, QWidget, QLabel, QLineEdit)
import subprocess

class Ui_yay_plus_MainWindow(object):
    def setupUi(self, yay_plus):
        if not yay_plus.objectName():
            yay_plus.setObjectName(u"yay_plus")
        yay_plus.resize(800, 600)
        self.setWindowTitle("yay+ Main Window")
        self.centralwidget = QWidget(yay_plus)
        self.centralwidget.setObjectName(u"centralwidget")
        self.pushButton = QPushButton(self.centralwidget)
        self.pushButton.setObjectName(u"pushButton")
        self.pushButton.setGeometry(QRect(60, 110, 211, 91))
        self.pushButton_2 = QPushButton(self.centralwidget)
        self.pushButton_2.setObjectName(u"pushButton_2")
        self.pushButton_2.setGeometry(QRect(550, 110, 211, 91))
        self.pushButton_3 = QPushButton(self.centralwidget)
        self.pushButton_3.setObjectName(u"pushButton_3")
        self.pushButton_3.setGeometry(QRect(60, 300, 701, 121))
        self.label = QLabel(self.centralwidget)
        self.label.setObjectName(u"label")
        self.label.setGeometry(QRect(70, 30, 661, 41))
        yay_plus.setCentralWidget(self.centralwidget)
        self.statusbar = QStatusBar(yay_plus)
        self.statusbar.setObjectName(u"statusbar")
        yay_plus.setStatusBar(self.statusbar)

        self.retranslateUi(yay_plus)
        self.pushButton.pressed.connect(OnButtonPressed)

        def OnButtonPressed():
            yay_plus.close()
            Install_Package = Ui_yay_plus_MainWindow(None, 'Install Package')
            Install_Package.show()

        QMetaObject.connectSlotsByName(yay_plus)
    # setupUi

    def retranslateUi(self, yay_plus):
        yay_plus.setWindowTitle(QCoreApplication.translate("yay+ Main Window", u"yay+ Main Window", None))
        self.pushButton.setText(QCoreApplication.translate("yay+ Main Window", u"\u5b89\u88c5\u8f6f\u4ef6/Install package", None))
        self.pushButton_2.setText(QCoreApplication.translate("yay+ Main Window", u"\u5347\u7ea7yay+/Upgrade yay+", None))
        self.pushButton_3.setText(QCoreApplication.translate("yay+ Main Window", u"\u9000\u51fa/Exit", None))
        self.label.setText(QCoreApplication.translate("yay+ Main Window", u"<html><head/><body><p align=\"center\"><span style=\" font-size:24pt; font-weight:700;\">yay+</span></p></body></html>", None))
    # retranslateUi

class Install_Package(object):
    def setupUi(self, installer):
        if not installer.objectName():
            installer.setObjectName(u"installer")
        installer.resize(800, 600)
        self.centralwidget = QWidget(installer)
        self.centralwidget.setObjectName(u"centralwidget")
        self.lineEdit = QLineEdit(self.centralwidget)
        self.lineEdit.setObjectName(u"lineEdit")
        self.lineEdit.setGeometry(QRect(150, 110, 511, 41))
        self.pushButton = QPushButton(self.centralwidget)
        self.pushButton.setObjectName(u"pushButton")
        self.pushButton.setGeometry(QRect(630, 480, 141, 61))
        installer.setCentralWidget(self.centralwidget)
        self.statusbar = QStatusBar(installer)
        self.statusbar.setObjectName(u"statusbar")
        installer.setStatusBar(self.statusbar)

        self.retranslateUi(installer)
        self.pushButton.pressed.connect(OnButtonPressed)

        def OnButtonPressed():
            global text
            text = self.lineEdit.text()
            installer.close()

        QMetaObject.connectSlotsByName(installer)
    # setupUi

    def retranslateUi(self, installer):
        installer.setWindowTitle(QCoreApplication.translate("yay+ Install Window", u"yay+ Main Window", None))
        self.lineEdit.setText(QCoreApplication.translate("yay+ Install Window", u"\u8bf7\u8f93\u5165\u60a8\u60f3\u8981\u7684\u8f6f\u4ef6\u5305\u7684\u540d\u79f0\uff08AUR\u3001pacman\u7686\u53ef\uff0c\u4f1a\u81ea\u52a8\u8bc6\u522b\uff09", None))
        self.pushButton.setText(QCoreApplication.translate("yay+ Install Window", u"OK", None))
    # retranslateUi

