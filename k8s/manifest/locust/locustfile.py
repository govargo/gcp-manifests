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
    self.headers = {"Content-Type": "application/json", "User-Agent": "UnityPlayer"}

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
      registration_response = self.client.post("/registration", headers=self.headers,
                                               name="/registration",
                                               json={"name": "test-" + str(
                                                 random.randint(0, 10000))})
    except (json.JSONDecodeError, TypeError) as e:
      print(e)
      print("[DEBUG] Registration response: {}".format(registration_response))
      return

    if registration_response.status_code == 200:
      pass
    elif registration_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry raidbattle")
      return self.register_and_login()

    # Get user_id
    self.user_id = (registration_response.json()["user_profile"]["user_id"])
    print("registered user id: " + self.user_id)

    # Login
    login_url = "/users/" + self.user_id + "/login"
    self.client.post(login_url, headers=self.headers,
                     name="/users/[user_id]/login",
                     json={"client_master_version": "2022061301"})

  def start_quest(self, quest_id):
    start_url = QUEST_DATA[quest_id]["start_url"].format(user_id=self.user_id)
    self.client.post(start_url, headers=self.headers,
                     name="/users/[user_id]/quests/[quest_id]/start",
                     json={"client_master_version": "2022061301"})

  def end_quest(self, quest_id):
    end_url = QUEST_DATA[quest_id]["end_url"].format(user_id=self.user_id)
    self.client.post(end_url,
                     headers=self.headers,
                     name="/users/[user_id]/quests/[quest_id]/end",
                     json={
                       "client_master_version": "2022061301",
                       "score": 100,
                       "clear_time": 20
                     })

  def get_quest_ranking(self, quest_id):
    ranking_url = QUEST_DATA[quest_id]["ranking_url"]
    self.client.get(ranking_url, headers=self.headers,
                    name="/quests/[quest_id]/ranking")

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
    raidbattle_response = self.client.post(raidbattle_url, headers=self.headers,
                                           name="/users/[user_id]/quests"
                                                "/raidbattle")

    if raidbattle_response.status_code == 200:
      pass
    elif raidbattle_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry raidbattle")
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
    shop_response = self.client.post(shop_url, headers=self.headers,
                                     name="/shops/[shop_id]",
                                     json={
                                       "client_master_version": "2022061301",
                                       "user_id": self.user_id
                                     })
    if shop_response.status_code == 200:
      pass
    elif shop_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry shop item")
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
    character_response = self.client.get(character_list_url, headers=self.headers,
                                         name="/users/[user_id]/characters?["
                                              "character_id]")

    if character_response.status_code == 200:
      pass
    elif character_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry character list")
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
      character_sell_response = self.client.delete(character_sell_url,
                                                   name=
                                                   "/users/[user_id]/characters"
                                                   "/[character_id]",
                                                   headers=self.headers)

      if character_sell_response.status_code == 200:
        pass
      elif character_sell_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry character sell")
        return self.character()

  @task(7)
  def gacha(self):
    # Use shop for get user_profile
    shop_response = self.client.post("/shops/item_120", headers=self.headers,
                                     name="/shops/item_120",
                                     json={
                                       "client_master_version": "2022061301",
                                       "user_id": self.user_id
                                     })

    if shop_response.status_code == 200:
      pass
    elif shop_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry shop item for gacha")
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
      gacha1_response = self.client.post("/gachas/1", headers=self.headers,
                                         name="/gachas/1",
                                         json={
                                           "client_master_version": "2022061301",
                                           "user_id": self.user_id
                                         })
      if gacha1_response.status_code == 200:
        pass
      elif gacha1_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry gacha1")
        return self.gacha()

    if friend_coin > 5:
      gacha2_response = self.client.post("/gachas/2", headers=self.headers,
                                         name="/gachas/2",
                                         json={
                                           "client_master_version": "2022061301",
                                           "user_id": self.user_id
                                         })
      if gacha2_response.status_code == 200:
        pass
      elif gacha2_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry gacha2")
        return self.gacha()

  @task(5)
  def present(self):
    # Get Present List
    present_list_url = "/users/" + self.user_id + "/presents?client_master_version=2022061301"
    present_response = self.client.get(present_list_url, headers=self.headers,
                                       name="/users/[user_id]/presents")

    if present_response.status_code == 200:
      pass
    elif present_response.status_code == 401:
      self.get_refresh_token(api_key)
      print("token is refreshed. retry present list")
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
      present_get_response = self.client.get(present_get_url, headers=self.headers,
                                             name="/users/[user_id]/presents"
                                                  "/[present_id]")
      if present_get_response.status_code == 200:
        pass
      elif present_get_response.status_code == 401:
        self.get_refresh_token(api_key)
        print("token is refreshed. retry present get")
        return self.gacha()


class Run(HttpUser):
  tasks = {TestScenarioCase: 1}
  wait_time = between(0.5, 3)
