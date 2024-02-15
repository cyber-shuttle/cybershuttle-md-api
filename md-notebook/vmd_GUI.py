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
                              QVBoxLayout, QWidget, QLabel, QProgressBar)

from PySide6 import QtCore, QtGui, QtWidgets



from MainWindow import Ui_MainWindow

# Icons
tick = QtGui.QImage('img/tick.png')
cross = QtGui.QImage('img/cross.png')



class ExpModel(QtCore.QAbstractListModel):
    def __init__(self, todos=None):
        super().__init__()
        self.experiments = todos or []

    def data(self, index, role):
        if role == Qt.DisplayRole:
            name, experimentStatus, experimentId = self.experiments[index.row()]
            return name

        if role == Qt.DecorationRole:
            _ , experimentStatus, _ = self.experiments[index.row()]
            if experimentStatus == 'COMPLETED':
                return tick
            
            if experimentStatus == 'FAILED':
                return cross


    def rowCount(self, index):
        return len(self.experiments)

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
    


class TodoModel(QtCore.QAbstractListModel):
    def __init__(self, todos=None):
        super().__init__()
        self.todos = todos or []

    def data(self, index, role):
        if role == Qt.DisplayRole:
            status, text = self.todos[index.row()]
            return text


    def rowCount(self, index):
        return len(self.todos)


# class MyApp(QMainWindow):
class MainWindow(QtWidgets.QMainWindow, Ui_MainWindow):
    def __init__(self):
        super().__init__()

        self.access_token = get_access_token_or_error()

        self.setupUi(self)
        self.exp_model = ExpModel()
        self.experimentView.setModel(self.exp_model)

        self.file_model = FileModel()
        self.fileView.setModel(self.file_model)
        self.setWindowTitle("CyberShuttle App")
        
        # Button actions
        self.Connect.clicked.connect(self.connect_cybershuttle)
        self.listExperiments.clicked.connect(self.list_experiments)
        self.downloadExperiment.clicked.connect(self.download_experiment)
        self.listFiles.clicked.connect(self.list_files)
        self.downloadFile.clicked.connect(self.download_file)

        self.experimentId = []
        self.all_experiments = []
        self.experiments_files = []

    def connect_cybershuttle(self):
        # Code to (re)connect to CyberShuttle goes here
        import warnings
        warnings.filterwarnings('ignore')

        from cybershuttle_md_cli import auth
        auth.do_authorization_flow('./settings-NAMD.ini')

        from cybershuttle_md_cli.experiment_util import ExperimentUtil
        experiment_util = ExperimentUtil("./settings-NAMD.ini")
        logger = logging.getLogger(__name__)

        print("Connected to CyberShuttle")


    def list_experiments(self) :
        from cybershuttle_md_cli.experiment_util import ExperimentUtil
        experiment_util = ExperimentUtil("./settings-NAMD.ini")
        
        # all_exp = experiment_util.show_experiments()
        self.all_experiments =  experiment_util.show_experiments()

        l = ['name','experimentStatus','experimentId']
        # for e in all_exp : 
        #     self.exp_model.experiments.append(tuple(map(vars(e).get, l)))
        #     self.exp_model.layoutChanged.emit()
        for e in self.all_experiments : 
            self.exp_model.experiments.append(tuple(map(vars(e).get, l)))
            self.exp_model.layoutChanged.emit()

    
    def list_files(self) :
        from cybershuttle_md_cli.experiment_util import ExperimentUtil
        experiment_util = ExperimentUtil("./settings-NAMD.ini")
        
        self.experiments_files = []

        self.file_model.files = []
        self.file_model.layoutChanged.emit()

        indexes = self.experimentView.selectedIndexes()

        if indexes : 
            index = indexes[0]
            row = index.row()
            self.experimentId = vars(self.all_experiments[row]).get('experimentId')
            # Keep selection
            #self.experimentView.clearSelection()

            print(self.experimentId)

            self.experiments_files = experiment_util.get_all_files_for_experiment(self.experimentId)
            for f in self.experiments_files.get('files') :
                self.file_model.files.append(f.get('name'))
                self.file_model.layoutChanged.emit()

    def download_file(self) :

        indexes = self.fileView.selectedIndexes()
        if indexes : 
            index = indexes[0]
            row = index.row()
            f_name = self.experiments_files.get('files')[row].get('name')
            f_url = self.experiments_files.get('files')[row].get('downloadURL')
            
            # Download file            
            headers = {"Authorization": f"Bearer {self.access_token}"}
            r = requests.get(f_url,headers=headers)
            with open (f_name,'w') as f :
                f.write(r.content.decode())

            print(f'''
                    experimentId: {self.experimentId}
                    name : {self.experiments_files.get('files')[row].get('name')}
                    downloadURL: {self.experiments_files.get('files')[row].get('downloadURL')}
                  ''')            

            # Keep selection
            #self.fileView.clearSelection()

    def download_experiment(self) :
        from cybershuttle_md_cli.experiment_util import ExperimentUtil
        experiment_util = ExperimentUtil("./settings-NAMD.ini")

        indexes = self.experimentView.selectedIndexes()

        if indexes : 
            index = indexes[0]
            row = index.row()
            self.experimentId = vars(self.all_experiments[row]).get('experimentId')
            
            # Keep selection
            #self.experimentView.clearSelection()
            print(f'Downloading {self.experimentId}')
            experiment_util.download_experiment(self.experimentId)


    def delete(self):
        indexes = self.todoView.selectedIndexes()
        
        if indexes:
            # Indexes is a list of a single item in single-select mode.
            index = indexes[0]
            # Remove the item and refresh.
            del self.model.todos[index.row()]
            self.model.layoutChanged.emit()
            # Clear the selection (as it is no longer valid).
            self.todoView.clearSelection()




if __name__ == "__main__":
    app = QApplication(sys.argv)
    myapp = MainWindow()
    myapp.show()
    sys.exit(app.exec())

