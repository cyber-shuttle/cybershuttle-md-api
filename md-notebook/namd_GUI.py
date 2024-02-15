import sys

import cgi
import fnmatch
import io
import logging
import os
import threading
import time
import zipfile
from datetime import datetime
from pathlib import Path
from urllib.parse import quote

import ipywidgets as widgets
import jwt
import requests
from airavata.model.experiment.ttypes import ExperimentSearchFields
from airavata.model.status.ttypes import ExperimentState, ExperimentStatus
from airavata_sdk.clients.api_server_client import APIServerClient
from airavata_sdk.clients.keycloak_token_fetcher import Authenticator
from airavata_sdk.clients.utils.api_server_client_util import APIServerClientUtil
from airavata_sdk.clients.utils.data_model_creation_util import DataModelCreationUtil
from airavata_sdk.transport.settings import ExperimentSettings, GatewaySettings
from cybershuttle_md_cli.auth import get_access_token_or_error

# Example experiment
experimentId='3bpm_eaf485ee-7a2f-450d-ba1b-7cff20bb1bc5'

from PySide6.QtCore import Qt

from PySide6.QtWidgets import (QApplication, QMainWindow, QPushButton, 
                              QVBoxLayout, QWidget, QLabel, QProgressBar,
                              QFileDialog)

from PySide6 import QtCore, QtGui, QtWidgets



from SubmintWindow import Ui_MainWindow

# Icons
tick = QtGui.QImage('img/tick.png')
cross = QtGui.QImage('img/cross.png')


class FileModel(QtCore.QAbstractListModel):
    def __init__(self, todos=None):
        super().__init__()
        self.files = todos or []

    def data(self, index, role):
        if role == Qt.DisplayRole:
            text = self.files[index.row()]
            return text

    def rowCount(self, index):
        return len(self.files)
    

# class MyApp(QMainWindow):
class MainWindow(QtWidgets.QMainWindow, Ui_MainWindow):
    def __init__(self):
        super().__init__()

        self.access_token = []
        self.QwikMDFile = []
        self.experimentId = []
        self.all_experiments = []
        self.experiments_files = []

        # "access_token is not being properlly propaged after "connect_to_cybershuttle".
        # If you get an {"detail":"Token failed to authenticate"} do this:
        #  -> Press "Connect to CyberShuttle", the close the App.
        #  -> then re-enable the line bellow to get the token from MainWindow.
        # self.access_token = get_access_token_or_error()
        
        self.setupUi(self)
        
        self.input_model = FileModel()
        self.inputFileView.setModel(self.input_model)

        self.output_model = FileModel()
        self.outputFileView.setModel(self.output_model)

        self.setWindowTitle("NAMD - CyberShuttle App")      

        # Button actions
        self.Connect.clicked.connect(self.connect_cybershuttle)
        self.loadQwikMDFile.clicked.connect(self.getFileName)
        self.listInputFiles.clicked.connect(self.load_qwikmd)
        # self.listOutputFiles.clicked.connect()


    def connect_cybershuttle(self):
        # Code to (re)connect to CyberShuttle goes here
        import warnings
        warnings.filterwarnings('ignore')

        from cybershuttle_md_cli import auth
        auth.do_authorization_flow('./settings-NAMD.ini')

        from cybershuttle_md_cli.experiment_util import ExperimentUtil
        experiment_util = ExperimentUtil("./settings-NAMD.ini")
        logger = logging.getLogger(__name__)

        self.access_token = get_access_token_or_error()

        print("Connected to CyberShuttle")

    def getFileName(self):
        file_filter = 'QwikMD (*.json)'
        fileName = QFileDialog.getOpenFileName(self,
                                                "QwikMD File", 
                                                os.getcwd(), 
                                                "QwikMD Files (*.json)"
                                                )
        print(str(fileName))
        self.QwikMDFile = fileName[0]

    def load_qwikmd(self) :
        import json

        # Opening JSON file
        f = open(self.QwikMDFile)

        # returns JSON object as 
        # a dictionary
        data = json.load(f)

        d = data.get('namdFiles')[0].get('Input')

        self.input_model.files = [] 
        for f in d.keys() : 
            for x in d.get(f) : 
                self.input_model.files.append(x)
        self.input_model.layoutChanged.emit()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    myapp = MainWindow()
    myapp.show()
    sys.exit(app.exec())

