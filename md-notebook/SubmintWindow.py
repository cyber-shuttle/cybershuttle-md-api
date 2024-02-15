# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'mainwindow.ui'
##
## Created by: Qt User Interface Compiler version 6.6.1
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
from PySide6.QtWidgets import (QAbstractItemView, QApplication, QHBoxLayout, QLineEdit,
    QListView, QMainWindow, QMenuBar, QPushButton,
    QSizePolicy, QStatusBar, QVBoxLayout, QWidget,QProgressBar)

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        if not MainWindow.objectName():
            MainWindow.setObjectName(u"MainWindow")
        MainWindow.resize(400, 400)

        # Central QWidget
        self.centralwidget = QWidget(MainWindow)
        self.centralwidget.setObjectName(u"centralwidget")
        
        self.verticalLayout = QVBoxLayout(self.centralwidget)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.Connect = QPushButton(self.centralwidget)
        self.Connect.setObjectName(u"Connect")
        self.verticalLayout.addWidget(self.Connect)

        #############################################################
        # Load QwikMD files
        #############################################################
        self.loadQwikMDFile = QPushButton(self.centralwidget)
        self.loadQwikMDFile.setObjectName(u"loadQwikMDFile")
        self.verticalLayout.addWidget(self.loadQwikMDFile)

        #############################################################
        # Input files
        #############################################################
        self.listInputFiles = QPushButton(self.centralwidget)
        self.listInputFiles.setObjectName(u"listInputFiles")
        self.verticalLayout.addWidget(self.listInputFiles)

        # # Frame 1 - File list
        self.inputFileView = QListView(self.centralwidget)
        self.inputFileView.setObjectName(u"inputFileView")
        self.inputFileView.setSelectionMode(QAbstractItemView.SingleSelection)
        self.verticalLayout.addWidget(self.inputFileView)

        #############################################################
        # Output files
        #############################################################
        self.listOutputFiles = QPushButton(self.centralwidget)
        self.listOutputFiles.setObjectName(u"listOutputFiles")
        self.verticalLayout.addWidget(self.listOutputFiles)

        # # Frame 1 - File list
        self.outputFileView = QListView(self.centralwidget)
        self.outputFileView.setObjectName(u"outputFileView")
        self.outputFileView.setSelectionMode(QAbstractItemView.SingleSelection)
        self.verticalLayout.addWidget(self.outputFileView)


        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QMenuBar(MainWindow)
        self.menubar.setObjectName(u"menubar")
        self.menubar.setGeometry(QRect(0, 0, 275, 22))
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QStatusBar(MainWindow)
        self.statusbar.setObjectName(u"statusbar")
        MainWindow.setStatusBar(self.statusbar)

        self.retranslateUi(MainWindow)

        QMetaObject.connectSlotsByName(MainWindow)
    # setupUi

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QCoreApplication.translate("MainWindow", u"Todo", None))
        self.Connect.setText(QCoreApplication.translate("MainWindow", u"Connect to CyberShuttle", None))
        self.loadQwikMDFile.setText(QCoreApplication.translate("MainWindow", u"Load QwikMD File", None))
        self.listInputFiles.setText(QCoreApplication.translate("MainWindow", u"List Input Files", None))
        self.listOutputFiles.setText(QCoreApplication.translate("MainWindow", u"List Output Files", None))   

    # retranslateUi

