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
        # Experiments 
        #############################################################
        self.listExperiments = QPushButton(self.centralwidget)
        self.listExperiments.setObjectName(u"listExperiments")
        self.verticalLayout.addWidget(self.listExperiments)

        # Frame 1 - Experiment list
        self.experimentView = QListView(self.centralwidget)
        self.experimentView.setObjectName(u"experimentView")
        self.experimentView.setSelectionMode(QAbstractItemView.SingleSelection)
        self.verticalLayout.addWidget(self.experimentView)
        
        self.downloadExperiment = QPushButton(self.centralwidget)
        self.downloadExperiment.setObjectName(u"downloadExperiment")
        self.verticalLayout.addWidget(self.downloadExperiment)

        #############################################################
        # Input files
        #############################################################
        self.listFiles = QPushButton(self.centralwidget)
        self.listFiles.setObjectName(u"listFiles")
        self.verticalLayout.addWidget(self.listFiles)

        # # Frame 1 - File list
        self.fileView = QListView(self.centralwidget)
        self.fileView.setObjectName(u"fileView")
        self.fileView.setSelectionMode(QAbstractItemView.SingleSelection)
        self.verticalLayout.addWidget(self.fileView)

        #############################################################
        # Download file
        #############################################################
        self.downloadFile = QPushButton(self.centralwidget)
        self.downloadFile.setObjectName(u"downloadFile")
        self.verticalLayout.addWidget(self.downloadFile)

        self.progressBar = QProgressBar(self)
        self.progressBar.setObjectName(u"progressBar")
        self.verticalLayout.addWidget(self.progressBar)


        # # Frame 2 - Container 
        # self.widget = QWidget(self.centralwidget)
        # self.widget.setObjectName(u"widget")
        # self.horizontalLayout = QHBoxLayout(self.widget)
        # self.horizontalLayout.setObjectName(u"horizontalLayout")
        
        # # Frame 2 - Button 1
        # self.deleteButton = QPushButton(self.widget)
        # self.deleteButton.setObjectName(u"deleteButton")
        # self.horizontalLayout.addWidget(self.deleteButton)
        
        # # Frame 2 - Button 2
        # self.completeButton = QPushButton(self.widget)
        # self.completeButton.setObjectName(u"completeButton")
        # self.horizontalLayout.addWidget(self.completeButton)

        # # Frame 3 - Add 
        # self.verticalLayout.addWidget(self.widget)
        # self.todoEdit = QLineEdit(self.centralwidget)
        # self.todoEdit.setObjectName(u"todoEdit")
        # self.verticalLayout.addWidget(self.todoEdit)



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
        self.listExperiments.setText(QCoreApplication.translate("MainWindow", u"List Experiments", None))
        self.listFiles.setText(QCoreApplication.translate("MainWindow", u"List Files", None))
        self.downloadFile.setText(QCoreApplication.translate("MainWindow", u"Download File", None))
        self.downloadExperiment.setText(QCoreApplication.translate("MainWindow", u"Download Experiment (beta)", None))

    # retranslateUi

