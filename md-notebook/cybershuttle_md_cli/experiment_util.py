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

from .auth import get_access_token_or_error

logger = logging.getLogger(__name__)


class ExperimentUtil:
    def __init__(self, configuration_file) -> None:
        self.configuration_file = configuration_file
        access_token = get_access_token_or_error()
        self.access_token = access_token
        decode = jwt.decode(access_token, options={"verify_signature": False})
        self.user_id = decode["preferred_username"]
        self.authenticator = Authenticator(self.configuration_file)
        self.gateway_conf = GatewaySettings(configuration_file)
        self.experiment_conf = ExperimentSettings(configuration_file)
        self.airavata_util = APIServerClientUtil(
            self.configuration_file,
            username=self.user_id,
            password=None,
            gateway_id=self.gateway_conf.GATEWAY_ID,
            access_token=access_token,
        )
        self.data_model_client = DataModelCreationUtil(
            self.configuration_file,
            username=self.user_id,
            password=None,
            gateway_id=self.gateway_conf.GATEWAY_ID,
            access_token=access_token,
        )
        self.api_server_client = APIServerClient(self.configuration_file)
        self.gateway_url = "https://md.cybershuttle.org"

    def upload_input_file(self, f: Path) -> str:
        files = {"file": (f.name, f.open("rb"))}
        access_token = get_access_token_or_error()
        headers = {"Authorization": f"Bearer {access_token}"}
        resp = requests.post(
            "https://md.cybershuttle.org/api/upload", headers=headers, files=files
        )
        resp.raise_for_status()
        data = resp.json()
        product_uri = data["data-product"]["productUri"]
        return product_uri

    def get_input_file_by_name_or_pattern(
        self, input_files, filename=None, glob=None
    ) -> str:
        if filename is not None and filename in input_files:
            return input_files[filename]
        for name, input_file in input_files.items():
            if fnmatch.fnmatch(name, glob):
                return input_file

    def get_input_files_by_pattern(self, input_files, glob=None) -> list[str]:
        result = []
        for name, input_file in input_files.items():
            if fnmatch.fnmatch(name, glob):
                result.append(input_file)
        return result

    def launch_experiment(self, experiment_id):
        access_token = get_access_token_or_error()
        headers = {"Authorization": f"Bearer {access_token}"}
        resp = requests.post(
            f"https://md.cybershuttle.org/api/experiments/{quote(experiment_id)}/launch/",
            headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["success"]

    def get_all_files_for_experiment(self, experiment_id):
            access_token = get_access_token_or_error()
            headers = {"Authorization": f"Bearer {access_token}"}
            resp = requests.get(
                f"https://md.cybershuttle.org/api/experiment-storage/{quote(experiment_id)}/",
                headers=headers,
            )
            resp.raise_for_status()
            data = resp.json()
            return data

    def launch_namd(
        self,
        run_dir,
        md_conf_filename=None,
        pdb_filename=None,
        psf_filename=None,
        experiment_name=None,
        experiment_description=None,
        computation_resource_name=None,
        queue_name=None,
        node_count=None,
        cpu_count=None,
        walltime=None,
        auto_schedule=False,
        replica_count=1,
    ):
        run_dir = Path(run_dir)
        execution_id = self.airavata_util.get_execution_id(
            self.experiment_conf.APPLICATION_NAME
        )
        hosts = self.experiment_conf.COMPUTE_HOST_DOMAIN.split(",")

        computation_resource_name = (
            computation_resource_name
            if computation_resource_name is not None
            else hosts[0]
        )
        storage_id = self.airavata_util.get_storage_resource_id(
            self.experiment_conf.STORAGE_RESOURCE_HOST
        )

        # logger.info("creating experiment %s", experiment_name)
        if experiment_name is None:
            experiment_name = run_dir.parent.name
        experiment = (
            self.data_model_client.get_experiment_data_model_for_single_application(
                project_name=self.experiment_conf.PROJECT_NAME,
                application_name=self.experiment_conf.APPLICATION_NAME,
                experiment_name=experiment_name,
                description=experiment_description,
            )
        )

        # Upload input files
        file_uploads = {}
        for f in run_dir.iterdir():
            if not f.is_file():
                continue
            file_uploads[f.name] = self.upload_input_file(f)
            logger.debug(f"Uploaded {f.name} with id {file_uploads[f.name]}")

        queue_name = (
            queue_name if queue_name is not None else self.experiment_conf.QUEUE_NAME
        )

        node_count = (
            node_count if node_count is not None else self.experiment_conf.NODE_COUNT
        )

        cpu_count = (
            cpu_count if cpu_count is not None else self.experiment_conf.TOTAL_CPU_COUNT
        )

        walltime = (
            walltime if walltime is not None else self.experiment_conf.WALL_TIME_LIMIT
        )
        experiment = self.data_model_client.configure_computation_resource_scheduling(
            experiment_model=experiment,
            computation_resource_name=computation_resource_name,
            group_resource_profile_name=self.experiment_conf.GROUP_RESOURCE_PROFILE_NAME,
            storageId=storage_id,
            node_count=int(node_count),
            total_cpu_count=int(cpu_count),
            wall_time_limit=int(walltime),
            queue_name=queue_name,
            experiment_dir_path=None,
            auto_schedule=auto_schedule,
        )
        inputs = self.api_server_client.get_application_inputs(
            self.airavata_token, execution_id
        )
        input_mapping = {}
        input_mapping["Execution_Type"] = "CPU"
        input_mapping["MD-Instructions-Input"] = self.get_input_file_by_name_or_pattern(
            file_uploads, md_conf_filename, "*.conf"
        )
        input_mapping["Coordinates-PDB-File"] = self.get_input_file_by_name_or_pattern(
            file_uploads, pdb_filename, "*.pdb"
        )
        input_mapping[
            "Protein-Structure-File"
        ] = self.get_input_file_by_name_or_pattern(file_uploads, psf_filename, "*.psf")
        input_mapping["FF-Parameter-Files"] = self.get_input_files_by_pattern(
            file_uploads, glob="*.prm"
        )
        input_mapping["FF-Parameter-Files"].extend(
            self.get_input_files_by_pattern(file_uploads, glob="*.str")
        )

        for input in inputs:
            if input.name in input_mapping:
                if input.type == 4:
                    input.value = ",".join(input_mapping[input.name])
                else:
                    input.value = input_mapping[input.name]
        experiment.experimentInputs = inputs
        outputs = self.api_server_client.get_application_outputs(
            self.airavata_token, execution_id
        )
        experiment.experimentOutputs = outputs
        experiment_id = self.api_server_client.create_experiment(
            self.airavata_token, self.gateway_conf.GATEWAY_ID, experiment
        )
        logger.info(f"Created experiment with id {experiment_id}")

        success = self.launch_experiment(experiment_id)
        if success:
            logger.info(f"Successfully launched {experiment_id}")
        return experiment_id

    def launch_alphafold(
        self,
        run_dir,
        fasta_filename=None,
        experiment_name=None,
        experiment_description=None,
        computation_resource_name=None,
        queue_name=None,
        node_count=None,
        cpu_count=None,
        walltime=None,
        auto_schedule=False,
        maximum_template_date=None,
        model_preset="monomer",
    ):
        run_dir = Path(run_dir)
        execution_id = self.airavata_util.get_execution_id(
            self.experiment_conf.APPLICATION_NAME
        )
        hosts = self.experiment_conf.COMPUTE_HOST_DOMAIN.split(",")

        computation_resource_name = (
            computation_resource_name
            if computation_resource_name is not None
            else hosts[0]
        )
        storage_id = self.airavata_util.get_storage_resource_id(
            self.experiment_conf.STORAGE_RESOURCE_HOST
        )

        # logger.info("creating experiment %s", experiment_name)
        if experiment_name is None:
            experiment_name = run_dir.parent.name
        experiment = (
            self.data_model_client.get_experiment_data_model_for_single_application(
                project_name=self.experiment_conf.PROJECT_NAME,
                application_name=self.experiment_conf.APPLICATION_NAME,
                experiment_name=experiment_name,
                description=experiment_description,
            )
        )

        # Upload input files
        file_uploads = {}
        for f in run_dir.iterdir():
            if not f.is_file():
                continue
            file_uploads[f.name] = self.upload_input_file(f)
            logger.debug(f"Uploaded {f.name} with id {file_uploads[f.name]}")

        queue_name = (
            queue_name if queue_name is not None else self.experiment_conf.QUEUE_NAME
        )

        node_count = (
            node_count if node_count is not None else self.experiment_conf.NODE_COUNT
        )

        cpu_count = (
            cpu_count if cpu_count is not None else self.experiment_conf.TOTAL_CPU_COUNT
        )

        walltime = (
            walltime if walltime is not None else self.experiment_conf.WALL_TIME_LIMIT
        )
        experiment = self.data_model_client.configure_computation_resource_scheduling(
            experiment_model=experiment,
            computation_resource_name=computation_resource_name,
            group_resource_profile_name=self.experiment_conf.GROUP_RESOURCE_PROFILE_NAME,
            storageId=storage_id,
            node_count=int(node_count),
            total_cpu_count=int(cpu_count),
            wall_time_limit=int(walltime),
            queue_name=queue_name,
            experiment_dir_path=None,
            auto_schedule=auto_schedule,
        )
        inputs = self.api_server_client.get_application_inputs(
            self.airavata_token, execution_id
        )
        input_mapping = {}
        input_mapping[
            "Input Sequence(s) File"
        ] = self.get_input_file_by_name_or_pattern(
            file_uploads, fasta_filename, "*.fasta"
        )
        input_mapping["Maximum Template Date"] = (
            maximum_template_date if maximum_template_date else "2023-09-18"
        )
        input_mapping["MODEL_PRESET"] = model_preset

        for input in inputs:
            if input.name in input_mapping:
                if input.type == 4:
                    input.value = ",".join(input_mapping[input.name])
                else:
                    input.value = input_mapping[input.name]
        experiment.experimentInputs = inputs
        outputs = self.api_server_client.get_application_outputs(
            self.airavata_token, execution_id
        )
        experiment.experimentOutputs = outputs
        experiment_id = self.api_server_client.create_experiment(
            self.airavata_token, self.gateway_conf.GATEWAY_ID, experiment
        )
        logger.info(f"Created experiment with id {experiment_id}")

        success = self.launch_experiment(experiment_id)
        if success:
            logger.info(f"Successfully launched {experiment_id}")
        return experiment_id

    @property
    def airavata_token(self):
        access_token = get_access_token_or_error()
        return self.authenticator.get_airavata_authz_token(
            self.user_id, access_token, self.gateway_conf.GATEWAY_ID
        )

    def show_namd_runs(self, status=None, only_mine=True, limit=10, offset=0):
        filters = {}

        execution_id = self.airavata_util.get_execution_id(
            self.experiment_conf.APPLICATION_NAME
        )
        filters[ExperimentSearchFields.APPLICATION_ID] = execution_id
        if status is not None:
            filters[ExperimentSearchFields.STATUS] = status
        if only_mine:
            filters[ExperimentSearchFields.USER_NAME] = self.user_id
        experiments = self.api_server_client.search_experiments(
            self.airavata_token,
            self.gateway_conf.GATEWAY_ID,
            self.user_id,
            filters,
            limit=limit,
            offset=offset,
        )
        experiment_names = [widgets.HTML("<b>Name</b>")]
        experiment_statuses = [widgets.HTML("<b>Status</b>")]
        experiment_timestamps = [widgets.HTML("<b>Created</b>")]
        experiment_download_buttons = [widgets.HTML("<b>Download</b>")]
        for exp in experiments:
            experiment_names.append(widgets.Label(exp.name))
            experiment_statuses.append(widgets.Label(exp.experimentStatus))
            experiment_timestamps.append(
                widgets.Label(datetime.fromtimestamp(exp.creationTime / 1000).ctime())
            )
            download_button = widgets.Button(
                description="Download",
                icon="download",
            )
            download_button.on_click(
                self.get_download_handler(
                    exp.experimentId,
                )
            )
            if exp.experimentStatus != "COMPLETED":
                download_button.disabled = True
            experiment_download_buttons.append(download_button)
        return widgets.HBox(
            [
                widgets.VBox(experiment_names),
                widgets.VBox(experiment_statuses),
                widgets.VBox(experiment_timestamps),
                widgets.VBox(experiment_download_buttons),
            ]
        )

    def get_download_handler(self, experiment_id):
        def download_handler(b):
            b.description = "Downloading ..."
            b.disabled = True
            self.download_experiment(experiment_id)
            b.description = "Download"
            b.disabled = False

        return download_handler

    def download_experiment(self, experiment_id, output_dir="./outputs"):
        access_token = get_access_token_or_error()
        headers = {"Authorization": f"Bearer {access_token}"}
        r = requests.get(
            f"{self.gateway_url}/sdk/download-experiment-dir/{experiment_id}/",
            headers=headers,
        )
        r.raise_for_status()
        # get name of zip file as returned in HTTP response headers and name the output directory the same
        disposition = r.headers["Content-Disposition"]
        disp_value, disp_params = cgi.parse_header(disposition)
        filename, ext = os.path.splitext(disp_params["filename"])
        output_dir = Path(output_dir) / filename

        zipped = zipfile.ZipFile(io.BytesIO(r.content))
        zipped.extractall(output_dir)
        return output_dir

    def monitor_experiment(self, experiment_id):
        progress = widgets.IntProgress(value=0, min=0, max=10)
        style = {"description_width": "initial"}
        progress.style = style
        experiment = self.api_server_client.get_experiment(
            self.airavata_token, experiment_id
        )
        print(f"Monitoring experiment {experiment.experimentName}")

        def monitor_thread(progress: widgets.IntProgress, experiment_id):
            while True:
                status: ExperimentStatus = self.api_server_client.get_experiment_status(
                    self.airavata_token, experiment_id
                )
                state_name = ExperimentState._VALUES_TO_NAMES[status.state]
                progress.description = f"{state_name}: "
                if status.state == ExperimentState.EXECUTING:
                    progress.value = 5
                elif status.state == ExperimentState.COMPLETED:
                    progress.value = 10
                    progress.bar_style = "success"
                    break
                elif status.state == ExperimentState.CANCELED:
                    progress.value = 10
                    progress.bar_style = "warning"
                    break
                elif status.state == ExperimentState.FAILED:
                    progress.value = 10
                    progress.bar_style = "danger"
                    break
                time.sleep(30)

        thread = threading.Thread(target=monitor_thread, args=(progress, experiment_id))
        thread.start()
        return progress
