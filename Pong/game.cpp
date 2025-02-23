#include <iostream>
#include <raylib.h>

using namespace std;

int player_score = 0;
int cpu_score = 0;

void Score(int ch)
{
    if (player_score = 11)
    {
        ClearBackground(BLACK);
        DrawText("Player 1 WINS!!!", GetScreenWidth() / 2, GetScreenHeight() / 2, 100, GREEN);
    }
    if (cpu_score = 11)
    {
        if (ch == 1)
        {
            ClearBackground(BLACK);
            DrawText("CPU WINS!!!", GetScreenWidth() / 2, GetScreenHeight() / 2, 100, GREEN);
        }
        else if (ch == 2)
        {
            ClearBackground(BLACK);
            DrawText("Player 2 WINS!!!", GetScreenWidth() / 2, GetScreenHeight() / 2, 100, GREEN);
        }
    }
}
class Ball
{
public:
    float x, y;
    int vx, vy;
    int radius;

    void Draw()
    {
        DrawCircle(x, y, radius, WHITE);
    }
    void Update()
    {
        x += vx;
        y += vy;

        if (y + radius >= GetScreenHeight() || y - radius <= 0)
        {
            vy = -vy;
        }
        if (x + radius >= GetScreenWidth())
        {
            cpu_score++;
            Reset();
        }
        if (x - radius <= 0)
        {
            player_score++;
            Reset();
        }
    }

    void Reset()
    {
        x = GetScreenWidth() / 2;
        y = GetScreenHeight() / 2;

        int speeds[] = {1, -1};
        vx *= speeds[GetRandomValue(0, 1)];
        vy *= speeds[GetRandomValue(0, 1)];
    }
};

class PaddleR
{
protected:
    void Collision()
    {
        if (y < 0)
        {
            y = 0;
        }
        if (y + height >= GetScreenHeight())
        {
            y = GetScreenHeight() - height;
        }
    }

public:
    float x, y, width, height;
    int speed;

    void Draw()
    {
        DrawRectangleRounded(Rectangle{x, y, width, height}, 0.8, 0, WHITE);
    }
    void Update()
    {
        if (IsKeyDown(KEY_UP))
        {
            y -= speed;
        }
        if ((IsKeyDown(KEY_DOWN)))
        {
            y += speed;
        }
        Collision();
    }
};

class CPU : public PaddleR
{
public:
    void Update(int ball_y)
    {
        if (y + height / 2 > ball_y)
        {
            y -= speed;
        }
        if (y + height / 2 <= ball_y)
        {
            y += speed;
        }
        Collision();
    }
};

class PaddleL : public PaddleR
{
public:
    void Update()
    {
        if (IsKeyDown(KEY_W))
        {
            y -= speed;
        }
        if ((IsKeyDown(KEY_S)))
        {
            y += speed;
        }
        Collision();
    }
};

Ball pong;
PaddleR player1;
CPU comp;
PaddleL player2;

int main()
{
    int choice;
    cout << "\tPlay \n\t(1) vs. CPU\n\t(2) vs. Player\n";
    cin >> choice;
    const int scrWidth = 1280, scrHeigth = 800;
    InitWindow(scrWidth, scrHeigth, "Pong.exe");
    SetTargetFPS(60);

    pong.radius = 20;
    pong.x = scrWidth / 2;
    pong.y = scrHeigth / 2;
    pong.vx = 7;
    pong.vy = 7;

    player1.width = 25;
    player1.height = 120;
    player1.x = scrWidth - player1.width - 10;
    player1.y = scrHeigth / 2 - player1.height / 2;
    player1.speed = 7;

    player2.width = 25;
    player2.height = 120;
    player2.x = 10;
    player2.y = scrHeigth / 2 - 60;
    player2.speed = 7;

    comp.width = 25;
    comp.height = 120;
    comp.x = 10;
    comp.y = scrHeigth / 2 - 60;
    comp.speed = 7;
    if (choice == 1)
    {
        while (!WindowShouldClose())
        {
            BeginDrawing();
            DrawFPS(10, 10);
            ClearBackground(BLACK);

            DrawCircle(GetScreenWidth() / 2, GetScreenHeight() / 2, 150, GREEN);
            DrawCircle(GetScreenWidth() / 2, GetScreenHeight() / 2, 148, BLACK);
            DrawLine(scrWidth / 2, 0, scrWidth / 2, scrHeigth, GREEN);
            comp.Draw();
            player1.Draw();
            pong.Draw();
            pong.Update();
            comp.Update(pong.y);
            player1.Update();
            DrawText(TextFormat("%i", cpu_score), GetScreenWidth() / 4, 20, 80, GREEN);
            DrawText(TextFormat("%i", player_score), 3 * GetScreenWidth() / 4, 20, 80, GREEN);

            if (CheckCollisionCircleRec(Vector2{pong.x, pong.y}, pong.radius, Rectangle{player1.x, player1.y, player1.width, player1.height}))
            {
                pong.vx *= -1;
            }

            if (CheckCollisionCircleRec(Vector2{pong.x, comp.y}, pong.radius, Rectangle{comp.x, comp.y, comp.width, comp.height}))
            {
                pong.vx *= -1;
            }
            // Score(choice);
            EndDrawing();
        }
    }
    else
    {
        while (!WindowShouldClose())
        {
            BeginDrawing();
            DrawFPS(10, 10);
            ClearBackground(BLACK);

            DrawCircle(GetScreenWidth() / 2, GetScreenHeight() / 2, 150, GREEN);
            DrawCircle(GetScreenWidth() / 2, GetScreenHeight() / 2, 148, BLACK);
            DrawLine(scrWidth / 2, 0, scrWidth / 2, scrHeigth, GREEN);
            player2.Draw();
            player1.Draw();
            pong.Draw();
            pong.Update();
            player2.Update();
            player1.Update();
            DrawText(TextFormat("%i", cpu_score), GetScreenWidth() / 4, 20, 80, GREEN);
            DrawText(TextFormat("%i", player_score), 3 * GetScreenWidth() / 4, 20, 80, GREEN);

            if (CheckCollisionCircleRec(Vector2{pong.x, pong.y}, pong.radius, Rectangle{player1.x, player1.y, player1.width, player1.height}))
            {
                pong.vx *= -1;
            }

            if (CheckCollisionCircleRec(Vector2{pong.x, comp.y}, pong.radius, Rectangle{comp.x, comp.y, comp.width, comp.height}))
            {
                pong.vx *= -1;
            }
            // Score(choice);

            EndDrawing();
        }
    }
    CloseWindow();
    return 0;
}
