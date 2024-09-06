import json
import random
import socket
import time
import os
import requests

from locust import TaskSet, between, task, HttpUser, User

api_key = None

# Quest Data
QUEST_DATA = {
  1: {
    "start_url": "/users/{user_id}/quests/1/start",
    "end_url": "/users/{user_id}/quests/1/end",
    "ranking_url": "/quests/1/ranking"
  },
  2: {
    "start_url": "/users/{user_id}/quests/2/start",
    "end_url": "/users/{user_id}/quests/2/end",
    "ranking_url": "/quests/2/ranking"
  }
}

# Shop Item Data
SHOP_ITEMS = {
  "item_120": "/shops/item_120",
  "item_240": "/shops/item_240",
  "item_360": "/shops/item_360"
}


class TestScenarioCase(TaskSet):
  def __init__(self, parent: User):
    super().__init__(parent)
    self.user_id = ""
    self.ipaddress = None
    self.port = None
    self.tcp_client = None
    self.headers = {"Content-Type": "application/json",
                    "User-Agent": "UnityPlayer"}

  def on_start(self):
    global api_key
    api_key = os.getenv('API_KEY')

    # Check if api_key is found
    if api_key is None:
      print("Error: api_key not found in environment variables.")
      exit(1)

    auth_response = self.sign_in_anonymously(api_key)
    try:
      idToken = auth_response["idToken"]
      self.refresh_token = auth_response["refreshToken"]
    except (json.JSONDecodeError, TypeError, KeyError) as e:
      print(e)
      print("[DEBUG] Auth response: {}".format(auth_response))

    self.headers["Authorization"] = "Bearer " + idToken

    # Registration and Login
    self.register_and_login()

    # Tutorial
    tutorial_url = "/users/" + self.user_id + "/quests/0/tutorial"
    tutorial_response = self.client.post(tutorial_url,
                                         name="/users/[user_id]/quests/0"
                                              "/tutorial",
                                         headers=self.headers,
                                         json={
                                           "client_master_version": "2022061301"
                                         })
    try:
      tutorial_progress = tutorial_response.json()["user_profile"][
        "tutorial_progress"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Tutorial response: {}".format(tutorial_response))

    if tutorial_progress != 10:
      print("CHECK: tutorial progress is ",
            tutorial_response.json()["user_profile"]["tutorial_progress"])

  def on_stop(self):
    if self.tcp_client is not None:
      print("tcp_client found. start cleanup...")
      self.tcp_client.send(b"battle:::end\n")
      self.tcp_client.close()
      self.tcp_client = None
      self.ipaddress = None
      self.port = None
      print("end cleanup...")

    if self.tcp_client is None and self.ipaddress is not None and self.port is not None:
      print("start cleanup. crate new tcp_client...")
      self.tcp_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.tcp_client.settimeout(120)
      self.tcp_client.connect((self.ipaddress, int(self.port)))
      self.tcp_client.send(b"battle:::end\n")
      self.tcp_client.close()

  def sign_in_anonymously(self, api_key):
    # https://firebase.google.com/docs/reference/rest/auth#section-sign-in-anonymously
    uri = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}"
    data = json.dumps({"returnSecureToken": True})
    result = requests.post(url=uri,
                           headers={"Content-Type": "application/json"},
                           data=data)
    if result.status_code == 200:
      return result.json()
    elif result.status_code == 400:
      print("Too many requests. Maybe QUOTA EXCEEDED")
      time.sleep(60)
      return self.sign_in_anonymously(api_key)
    else:
      print("Error: ", result.json())

    return result.json()

  def get_refresh_token(self, api_key):
    # https://firebase.google.com/docs/reference/rest/auth#section-refresh-token
    uri = f"https://securetoken.googleapis.com/v1/token?key={api_key}"
    if "Authorization" in self.headers:
      del self.headers["Authorization"]

    body = "grant_type=refresh_token&refresh_token=" + self.refresh_token
    result = requests.post(url=uri,
                           headers={
                             "Content-Type": "application/x-www-form-urlencoded"},
                           data=body)

    if result.status_code == 200:
      idToken = result.json()["id_token"]
      self.headers["Authorization"] = "Bearer " + idToken
    if result.status_code == 400:
      print("error happened for refresh token")
      print(result.json())

  def register_and_login(self):
    try:
      # Registration
      with self.client.post("/registration",
                            headers=self.headers,
                            name="/registration",
                            json={"name": "test-" + str(
                              random.randint(0, 10000))
                                  },
                            catch_response=True) as registration_response:
        if registration_response.status_code == 200:
          registration_response.success()
          pass
        elif registration_response.status_code == 401:
          self.get_refresh_token(api_key)
          print("token is refreshed. retry registration")
          registration_response.success()
          return self.register_and_login()
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Registration response: {}".format(registration_response))
      return

    # Get user_id
    self.user_id = (registration_response.json()["user_profile"]["user_id"])
    print("registered user id: " + self.user_id)

    # Login
    login_url = "/users/" + self.user_id + "/login"
    with self.client.post(login_url,
                          headers=self.headers,
                          name="/users/[user_id]/login",
                          json={
                            "client_master_version": "2022061301"
                          },
                          catch_response=True) as login_response:
      if login_response.status_code == 200:
        login_response.success()
        pass
      elif login_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry login")
        login_response.success()
        return self.register_and_login()

  def start_quest(self, quest_id):
    start_url = QUEST_DATA[quest_id]["start_url"].format(user_id=self.user_id)
    with self.client.post(start_url,
                          headers=self.headers,
                          name="/users/[user_id]/quests/[quest_id]/start",
                          json={
                            "client_master_version": "2022061301"
                          },
                          catch_response=True) as start_response:
      if start_response.status_code == 200:
        start_response.success()
        pass
      elif start_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry quest_start")
        start_response.success()
        return self.register_and_login()

  def end_quest(self, quest_id):
    end_url = QUEST_DATA[quest_id]["end_url"].format(user_id=self.user_id)
    with self.client.post(end_url,
                          headers=self.headers,
                          name="/users/[user_id]/quests/[quest_id]/end",
                          json={
                            "client_master_version": "2022061301",
                            "score": 100,
                            "clear_time": 20
                          },
                          catch_response=True) as end_response:
      if end_response.status_code == 200:
        end_response.success()
        pass
      elif end_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry quest_end")
        end_response.success()
        return self.register_and_login()

  def get_quest_ranking(self, quest_id):
    ranking_url = QUEST_DATA[quest_id]["ranking_url"]
    with self.client.get(ranking_url,
                         headers=self.headers,
                         name="/quests/[quest_id]/ranking",
                         catch_response=True) as ranking_response:
      if ranking_response.status_code == 200:
        ranking_response.success()
        pass
      elif ranking_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry ranking")
        ranking_response.success()
        return self.register_and_login()

  @task(7)
  def quest1(self):
    self.start_quest(1)
    self.end_quest(1)
    self.get_quest_ranking(1)

  @task(1)
  def raidbattle(self):
    self.start_quest(2)
    self.raid_battle()
    self.end_quest(2)
    self.get_quest_ranking(2)

  def raid_battle(self):
    raidbattle_url = "/users/" + self.user_id + "/quests/raidbattle"
    with self.client.post(raidbattle_url,
                          headers=self.headers,
                          name="/users/[user_id]/quests"
                               "/raidbattle",
                          catch_response=True) as raidbattle_response:
      if raidbattle_response.status_code == 200:
        raidbattle_response.success()
        pass
      elif raidbattle_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry raidbattle")
        raidbattle_response.success()
        return self.raid_battle()

    try:
      connection = raidbattle_response.json()["connection"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] RaidBattle response: {}".format(raidbattle_response))
      return

    endpoint = connection.split(":")
    self.ipaddress = endpoint[0]
    self.port = endpoint[1]

    buffer_size = 4096

    # Join to gameserver and start raid battle
    self.tcp_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # Set timeout to 120s
    self.tcp_client.settimeout(120)
    self.tcp_client.connect((self.ipaddress, int(self.port)))
    join_response = self.tcp_client.recv(buffer_size)
    # print("[" + ipaddress + ":" + str(
    #   port) + "] " + "Received a response: {}".format(join_response))
    player = str(join_response).split(":::")
    player_name = player[0][2:]
    # print("[{}:{},{}] Joined".format(ipaddress, str(port), player_name))
    self.tcp_client.send(b"battle:::start\n")

    boss_max_hp = 300
    while data := self.tcp_client.recv(buffer_size):
      if str(data).__contains__("start"):
        # print("[{}:{},{}] started raidbattle".format(ipaddress, str(port),
        #                                              player_name))
        data = b"boss:::300\n"

      if str(data).__contains__("end"):
        # print("[{}:{},{}] end raidbattle".format(ipaddress, str(port),
        #                                          player_name))
        self.tcp_client.close()
        self.ipaddress = None
        self.port = None
        self.tcp_client = None
        return

      if str(data).__contains__("join"):
        continue

      if str(data).__contains__("leave"):
        continue

      damage = boss_max_hp - random.randint(1, 100)
      # print(
      #   "[{}:{},{}] player attack. damage: {}".format(ipaddress, str(port),
      #                                                 player_name, damage))
      self.tcp_client.send(bytes(
        player_name + ":::" + str(damage) + "\n", encoding='utf8'))

      boss_hp = str(data).split(":::")
      if len(boss_hp) > 2:
        # When the response such like
        # player2:83:::boss:217\nplayer1:0:::boss:217\n, ignore
        continue

      if str(boss_hp[1]).__contains__(":"):
        # split the response such like player1:98:::boss:202\n
        hp = boss_hp[1].split(":")
        boss_max_hp = int(hp[1][:-3])
      else:
        # split the response such like boss:::300\n
        boss_max_hp = int(boss_hp[1][:-3])

      # print(
      #   "[{}:{},{}] boss hp: {}".format(ipaddress, str(port), player_name,
      #                                   str(boss_max_hp)))
      time.sleep(3)

  @task(10)
  def shop_item(self, item_id='item_120'):
    shop_url = SHOP_ITEMS[item_id]
    with self.client.post(shop_url,
                          headers=self.headers,
                          name="/shops/[shop_id]",
                          json={
                            "client_master_version": "2022061301",
                            "user_id": self.user_id
                          },
                          catch_response=True) as shop_response:
      if shop_response.status_code == 200:
        shop_response.success()
        pass
      elif shop_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry shop item")
        shop_response.success()
        return self.shop_item()

  @task(10)
  def shop_item_120(self):
    self.shop_item("item_120")

  @task(10)
  def shop_item_240(self):
    self.shop_item("item_240")

  @task(10)
  def shop_item_360(self):
    self.shop_item("item_360")

  @task(7)
  def character(self):
    # Get Character List
    character_list_url = "/users/" + self.user_id + "/characters?client_master_version=2022061301"
    with self.client.get(character_list_url,
                         headers=self.headers,
                         name="/users/[user_id]/characters?["
                              "character_id]",
                         catch_response=True) as character_response:
      if character_response.status_code == 200:
        character_response.success()
        pass
      elif character_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry character list")
        character_response.success()
        return self.character()

    try:
      user_character = character_response.json()["user_character"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Character response: {}".format(character_response))
      return

    if user_character is not None:
      # Sell Character, if the user has
      character_sell_url = "/users/" + self.user_id + "/characters/" + \
                           character_response.json()["user_character"][0][
                             "id"] + "?client_master_version=2022061301"
      with self.client.delete(character_sell_url,
                              name=
                              "/users/[user_id]/characters"
                              "/[character_id]",
                              headers=self.headers,
                              catch_response=True) as character_sell_response:
        if character_sell_response.status_code == 200:
          character_sell_response.success()
          pass
        elif character_sell_response.status_code == 401:
          self.get_refresh_token(api_key)
          print("token is refreshed. retry character sell")
          character_sell_response.success()
          return self.character()

  @task(7)
  def gacha(self):
    # Use shop for get user_profile
    with self.client.post("/shops/item_120",
                          headers=self.headers,
                          name="/shops/item_120",
                          json={
                            "client_master_version": "2022061301",
                            "user_id": self.user_id
                          },
                          catch_response=True) as shop_response:
      if shop_response.status_code == 200:
        shop_response.success()
        pass
      elif shop_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry shop item for gacha")
        shop_response.success()
        return self.gacha()

    try:
      crystal = shop_response.json()["user_profile"]["crystal"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Shop response: {}".format(shop_response))
      return

    try:
      friend_coin = shop_response.json()["user_profile"]["friend_coin"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG]: Shop response {}".format(shop_response))
      return

    if crystal > 5:
      with self.client.post("/gachas/1",
                            headers=self.headers,
                            name="/gachas/1",
                            json={
                              "client_master_version": "2022061301",
                              "user_id": self.user_id
                            },
                            catch_response=True) as gacha1_response:
        if gacha1_response.status_code == 200:
          gacha1_response.success()
          pass
        elif gacha1_response.status_code == 401:
          self.get_refresh_token(api_key)
          print("token is refreshed. retry gacha1")
          gacha1_response.success()
          return self.gacha()

    if friend_coin > 5:
      with self.client.post("/gachas/2",
                            headers=self.headers,
                            name="/gachas/2",
                            json={
                              "client_master_version": "2022061301",
                              "user_id": self.user_id
                            },
                            catch_response=True) as gacha2_response:
        if gacha2_response.status_code == 200:
          gacha2_response.success()
          pass
        elif gacha2_response.status_code == 401:
          self.get_refresh_token(api_key)
          print("token is refreshed. retry gacha2")
          gacha2_response.success()
          return self.gacha()

  @task(5)
  def present(self):
    # Get Present List
    present_list_url = "/users/" + self.user_id + "/presents?client_master_version=2022061301"
    with self.client.get(present_list_url,
                                       headers=self.headers,
                                       name="/users/[user_id]/presents",
                                       catch_response=True) as present_response:
      if present_response.status_code == 200:
        present_response.success()
        pass
      elif present_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry present list")
        present_response.success()
        return self.gacha()

    try:
      present = present_response.json()["user_present"]
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Present response: {}".format(present_response))
      return

    if present is not None:
      # Get present, if the user has the present
      present_get_url = "/users/" + self.user_id + "/presents/" + \
                        present_response.json()["user_present"][0][
                          "present_id"] + "?client_master_version=2022061301"
      with self.client.get(present_get_url,
                           headers=self.headers,
                           name="/users/[user_id]/presents/[present_id]",
                           catch_response=True) as present_get_response:
        if present_get_response.status_code == 200:
          present_get_response.success()
          pass
        elif present_get_response.status_code == 401:
          self.get_refresh_token(api_key)
          print("token is refreshed. retry present get")
          present_get_response.success()
          return self.gacha()


class Run(HttpUser):
  tasks = {TestScenarioCase: 1}
  wait_time = between(0.5, 3)
